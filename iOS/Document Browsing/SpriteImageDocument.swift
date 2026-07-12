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

    /// The framework's file configuration (nil for a brand-new, unsaved
    /// document). Kept for future direct-URL access; optional so the size-based
    /// initializer — used for new documents and previews — needs no framework
    /// configuration to exist.
    let configuration: URLDocumentConfiguration?

    /// New (untitled) document: a blank transparent sprite of the given size.
    init(size: SpriteSize) {
        self.data = Self.blankPNG(size: size)
        self.configuration = nil
        UserDefaults.standard.incrementDocumentsCreatedCount()
    }

    /// Existing document opened from disk. `data` is filled by `apply(snapshot:)`.
    init(configuration: URLDocumentConfiguration) {
        self.data = Data()
        self.configuration = configuration
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

    // MARK: - PNG helpers

    private static func blankPNG(size: SpriteSize) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.width, height: size.height), format: format)
        return renderer.pngData { _ in /* transparent */ }
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
