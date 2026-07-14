import SwiftUI
import UIKit
import SpritePencilKit
import StoreKit
import UniformTypeIdentifiers

@MainActor @Observable
final class AppCoordinator: NSObject {

    var importingPaletteFromLospec: Palette? = nil
    var showingAppStoreEvent = false

    /// Single entry point for every incoming URL — custom schemes and
    /// universal links (via `handleBrowsingWeb`) alike.
    func handleIncoming(url: URL) {
        if url.isFileURL {
            // No-op for file URLs in this refactor. Previously would present the document.
        } else if url.path().contains("spritepencil/appstoreevent") {
            showingAppStoreEvent = true
        } else if url.path().contains("spritepencil/importfromapp") {
            importSpriteFromAppGroup()
        } else {
            handleCustomURL(url: url)
        }
    }

    func handleBrowsingWeb(activity: NSUserActivity) {
        if activity.activityType == NSUserActivityTypeBrowsingWeb, let incomingURL = activity.webpageURL {
            handleIncoming(url: incomingURL)
        }
    }

    func handleCustomURL(url: URL) {
        switch (url.scheme, url.host()) {
        case ("spritepencil", "importfromapp"):
            importSpriteFromAppGroup()
        case ("lospec-palette", _):
            Task { await openLospecURL(url) }
        default:
            print("Unhandled URL: \(url)")
        }
    }

    func importSpriteFromAppGroup() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id) else { return }
        let importSpriteImageURL = containerURL.appendingPathComponent("Import").appendingPathExtension("png")
        guard let imageData = try? Data(contentsOf: importSpriteImageURL) else { return }

        let preferedFileName = AppGroup.defaults?.string(forKey: AppGroup.Key.importSpriteName)

        let directoryURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let baseName = preferedFileName ?? NSLocalizedString("Sprite", comment: "Default image name")

        // Save into the user's documents (iCloud Drive when available), where
        // the document browser picks it up. Replaces the UIDocument save lost
        // in the DocumentGroup refactor, which silently discarded the data.
        // Detached: NSFileCoordinator can block on iCloud, so stay off main.
        Task.detached(priority: .userInitiated) {
            var destinationURL = directoryURL.appendingPathComponent(baseName).appendingPathExtension("png")
            var counter = 2
            while FileManager.default.fileExists(atPath: destinationURL.path) {
                destinationURL = directoryURL.appendingPathComponent("\(baseName) \(counter)").appendingPathExtension("png")
                counter += 1
            }
            var coordinatorError: NSError?
            NSFileCoordinator().coordinate(writingItemAt: destinationURL, options: .forReplacing, error: &coordinatorError) { url in
                do {
                    try imageData.write(to: url)
                } catch {
                    print("Unable to save imported sprite: \(error)")
                }
            }
            if let coordinatorError {
                print("Unable to coordinate imported sprite save: \(coordinatorError)")
            }
        }
    }

    func openLospecURL(_ url: URL) async {
        do {
            // Drives the "Add Palette" sheet.
            importingPaletteFromLospec = try await Palette.lospec(url)
        } catch {
            print(error)
        }
    }
}

@main
struct SpritePencilApp: App {

    init() {
        UserDefaults.standard.register()
        PaletteStore.shared.loadPalettes()

        AppGroup.defaults?.set(true, forKey: AppGroup.Key.ownsSpritePencil)

        // Create a file manually to get iCloud Drive to show up
        if let iCloudDriveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            do {
                try FileManager.default.createDirectory(at: iCloudDriveURL, withIntermediateDirectories: true)
                let testFileURL = iCloudDriveURL.appendingPathComponent("Developer Empty File").appendingPathExtension("txt")
                try "This file is used to create your iCloud Drive folder.".write(to: testFileURL, atomically: false, encoding: .utf8)
                try FileManager.default.removeItem(at: testFileURL)
            } catch {
                print("unable to create icloud drive folder")
            }
        } else {
            print("unable to get icloud url")
        }
    }

    @AppStorage(UserDefaults.Key.documentsClosedCount) private var documentsClosedCount = 0

    @Environment(\.requestReview) private var requestReview

    @State var documentCreationContinuation: CheckedContinuation<SpriteSize, any Error>?
    @State var isTemplatePickerPresented = false
    @State var appCoordinator = AppCoordinator()

    var body: some Scene {
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        DocumentGroupLaunchScene("Sprite Pencil", backgroundStyle: Color.yellow) {
            // Under the SDK 27 document model, creation routes through the
            // `DocumentGroup`'s `makeDocument` (below); the button just triggers
            // it with our creation source. `makeDocument` presents the template
            // picker via the continuation this sheet resumes.
            NewDocumentButton("New Sprite", contentType: .png, source: .newSprite)
                .alert("Event Intro", isPresented: $appCoordinator.showingAppStoreEvent) {
                    Button("OK", role: .close) { }
                } message: {
                    Text("Now let's celebrate by opening a new sprite and using the new tools!")
                }
                // `onDismiss` catches the swipe-down that skips the picker's own
                // buttons; without it the continuation leaks and creation hangs.
                .sheet(isPresented: $isTemplatePickerPresented, onDismiss: {
                    documentCreationContinuation?.resume(throwing: CancellationError())
                    documentCreationContinuation = nil
                }) {
                    TemplatePickerView { selectedSize in
                        guard let selectedSize else {
                            documentCreationContinuation?.resume(throwing: CancellationError())
                            documentCreationContinuation = nil
                            isTemplatePickerPresented = false
                            return
                        }
                        documentCreationContinuation?.resume(returning: selectedSize)
                        documentCreationContinuation = nil
                        isTemplatePickerPresented = false
                    }
                }
                .sheet(item: $appCoordinator.importingPaletteFromLospec) { palette in
                    NavigationStack {
                        AddPaletteView(palette: palette, fromLospec: true)
                    }
                }
                .onOpenURL { url in
                    appCoordinator.handleIncoming(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    appCoordinator.handleBrowsingWeb(activity: activity)
                }
        }
        #endif

        DocumentGroup(editor: { (document: SpriteImageDocument) in
            EditorView(document: document)
                .alert("Event Intro", isPresented: $appCoordinator.showingAppStoreEvent) {
                    Button("OK", role: .close) { }
                } message: {
                    Text("Now let's celebrate by opening a new sprite and using the new tools!")
                }
                .onDisappear {
                    if [5, 20, 50, 100].contains(documentsClosedCount) {
                        requestReview()
                    }
                }
                .sheet(item: $appCoordinator.importingPaletteFromLospec) { palette in
                    NavigationStack {
                        AddPaletteView(palette: palette, fromLospec: true)
                    }
                }
                .onOpenURL { url in
                    appCoordinator.handleIncoming(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    appCoordinator.handleBrowsingWeb(activity: activity)
                }
        }, makeDocument: { configuration, _ in
            // Opening an existing file: the framework fills `data` via the reader.
            if configuration.fileURL != nil {
                return SpriteImageDocument(configuration: configuration)
            }
            // New document. Mac Catalyst has no launch scene to host the picker,
            // so it keeps the old default-size behavior.
            #if targetEnvironment(macCatalyst)
            return SpriteImageDocument(size: .defaultSize)
            #else
            let size = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SpriteSize, any Error>) in
                documentCreationContinuation = continuation
                isTemplatePickerPresented = true
            }
            return SpriteImageDocument(size: size)
            #endif
        })
    }

}

extension DocumentCreationSource {
    /// Identifies the "New Sprite" launch-scene button so `makeDocument` knows a
    /// fresh sprite (with the template picker) was requested.
    static let newSprite = DocumentCreationSource(id: "newSprite")
}
