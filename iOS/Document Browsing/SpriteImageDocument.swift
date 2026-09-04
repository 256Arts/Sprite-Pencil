import SwiftUI
import UniformTypeIdentifiers
import ImageIO
import UIKit

/// The sprite document. Migrated from `FileDocument` (value) to the SDK 27
/// `ReadableDocument` / `WritableDocument` model (reference `@Observable`),
/// so reading and — crucially — PNG **encoding** happen off the main actor in
/// the writer instead of on-main in the editor's old hand-rolled coalescing.
///
/// - Reading snapshot is the raw PNG `Data`; the editor seeds its canvas from
///   `data` once the document opens (unchanged read path).
/// - Writing snapshot is the live `CGImage` captured cheaply on the main actor;
///   the writer encodes it to PNG in the background.
@Observable
final class SpriteImageDocument: Document {

    static let readableContentTypes: [UTType] = [.png, .jpeg]
    static let writableContentTypes: [UTType] = [.png]

    /// PNG bytes as last read from disk (or the blank template for a new
    /// document). The editor reads this once to build its drawing context.
    var data: Data

    /// The editor's latest canvas image, pushed on each drawing change.
    /// Captured in `snapshot(contentType:)` and PNG-encoded off the main actor
    /// by the writer. `@ObservationIgnored` — it's a save-time handoff, not
    /// view state, so it must not invalidate the editor on every stroke.
    @ObservationIgnored var currentImage: CGImage?

    /// The framework's file configuration. Its `fileURL` is nil until the
    /// document has a file on disk, so `isNewDocument` — not this — is what
    /// distinguishes a fresh sprite from one opened from the browser.
    /// Optional only so previews can build a document with no framework
    /// configuration to hand it.
    let configuration: URLDocumentConfiguration?

    /// True when the document was created blank rather than read from disk.
    /// Drives the editor's one-time "Permanent Edits" warning, which only
    /// applies to files that already existed.
    let isNewDocument: Bool

    /// New (untitled) document: a blank transparent sprite of the given size.
    init(size: SpriteSize, configuration: URLDocumentConfiguration? = nil) {
        self.data = Self.blankPNG(size: size)
        self.configuration = configuration
        self.isNewDocument = true
        UserDefaults.standard.incrementDocumentsCreatedCount()
    }

    /// A document with no file behind it, built from PNG bytes the app already has.
    /// Used for the screenshot run's seeded sprite (see `ScreenshotMode`); `isNewDocument`
    /// keeps the "Permanent Edits" warning out of the shots, as for any untitled sprite.
    init(data: Data) {
        self.data = data
        self.configuration = nil
        self.isNewDocument = true
    }

    /// Existing document opened from disk. `data` is filled by `apply(snapshot:)`.
    init(configuration: URLDocumentConfiguration) {
        self.data = Data()
        self.configuration = configuration
        self.isNewDocument = false
    }

    // MARK: - Reading

    nonisolated func reader(configuration: sending ReadConfiguration) -> sending FileWrapperDocumentReader<Data> {
        FileWrapperDocumentReader(configuration) { fileWrapper in
            guard let contents = fileWrapper.regularFileContents else {
                throw CocoaError(.fileReadCorruptFile)
            }
            return contents
        }
    }

    @MainActor
    func apply(snapshot: Data, previous: Data?) async throws {
        self.data = snapshot
        // Drop any stale editor image; the editor re-seeds from `data`.
        self.currentImage = nil
    }

    // MARK: - Writing

    /// A `Sendable` wrapper so the immutable `CGImage` can cross to the
    /// background writer. `CGImage` is immutable, hence `@unchecked Sendable`.
    struct WriteSnapshot: @unchecked Sendable {
        let image: CGImage
    }

    nonisolated func writer(configuration: sending WriteConfiguration) -> sending FileWrapperDocumentWriter<WriteSnapshot> {
        FileWrapperDocumentWriter(configuration) { (snapshot: WriteSnapshot, _: FileWrapper?) in
            // Runs off the main actor: this is the expensive PNG encode that
            // used to stutter the canvas when done inline on every touch sample.
            let data = try SpriteImageDocument.pngData(from: snapshot.image)
            return FileWrapper(regularFileWithContents: data)
        }
    }

    @MainActor
    func snapshot(contentType: UTType) async throws -> sending WriteSnapshot {
        if let currentImage {
            return WriteSnapshot(image: currentImage)
        }
        // The editor hasn't drawn yet (e.g. saved immediately after open):
        // fall back to the last-read/seed PNG.
        guard let image = UIImage(data: data)?.cgImage else {
            throw CocoaError(.fileWriteUnknown)
        }
        return WriteSnapshot(image: image)
    }

    // MARK: - Manual saving

    /// Writes `image` to the document's file right now, without going through
    /// SwiftUI's autosave.
    ///
    /// SwiftUI decides a document has unsaved changes purely from undo actions
    /// registered on the document's `UndoManager`. With autosaving turned off
    /// the editor points the drawing engine at a private manager instead, so
    /// the framework never sees a change and never touches the file — which is
    /// the whole point of that mode, but it also means the editor has to do the
    /// one write itself when the person confirms.
    ///
    /// Throws `CocoaError(.fileWriteInvalidFileName)` if the document has no
    /// file yet (it isn't ours to place — the browser owns naming).
    @MainActor
    func saveNow(image: CGImage) async throws {
        guard let configuration, let fileURL = configuration.fileURL else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        // Same off-main encode the writer does; only the write itself is on
        // main, and a sprite PNG is a few kilobytes.
        let encoded = try await Self.encodePNG(WriteSnapshot(image: image))

        var coordinationError: NSError?
        var writeError: (any Error)?
        configuration.makeFileCoordinator().coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinationError) { url in
            do {
                try encoded.write(to: url, options: .atomic)
            } catch {
                writeError = error
            }
        }
        if let coordinationError { throw coordinationError }
        if let writeError { throw writeError }

        data = encoded
        currentImage = image
        // Keep the framework's idea of the file in step with the write we just
        // made, so it doesn't read this back as an outside edit.
        configuration.lastContentModificationDate = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .now
    }

    // MARK: - PNG helpers

    private static func blankPNG(size: SpriteSize) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.width, height: size.height), format: format)
        return renderer.pngData { _ in /* transparent */ }
    }

    /// `pngData(from:)` hopped off the main actor, for `saveNow(image:)`.
    /// `@concurrent` is what moves it: a plain `nonisolated async` function
    /// would inherit the caller's actor and encode on main.
    @concurrent
    nonisolated private static func encodePNG(_ snapshot: WriteSnapshot) async throws -> Data {
        try pngData(from: snapshot.image)
    }

    /// Encodes a `CGImage` to PNG via ImageIO — safe to call off the main actor
    /// (unlike the previous `UIImage.pngData()` path, which ran on-main).
    nonisolated static func pngData(from image: CGImage) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return output as Data
    }
}
