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

    struct LospecPalette: Codable {
        let name: String
        let author: String
        let colors: [String]
    }

    func openLospecURL(_ url: URL) async {
        guard url.scheme == "lospec-palette", let paletteSlug = url.host() else { return }
        guard let jsonURL = URL(string: "https://lospec.com/palette-list/\(paletteSlug).json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: jsonURL)
            let lospecPalette = try JSONDecoder().decode(LospecPalette.self, from: data)
            var colors = [ColorComponents]()
            for hex in lospecPalette.colors {
                guard let components = ColorComponents(hex: hex) else { return }
                colors.append(components)
            }
            // Drives the "Add Palette" sheet.
            importingPaletteFromLospec = Palette(name: lospecPalette.name, specialCase: nil, colors: colors, defaultGroupLength: 1)
        } catch {
            print(error)
        }
    }
}

@main
struct SpritePencilApp: App {

    enum DocumentCreationError: Error {
        case userCancelled
    }

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

    @State var documentCreationContinuation: CheckedContinuation<SpriteImageDocument, any Error>?
    @State var isTemplatePickerPresented = false
    @State var appCoordinator = AppCoordinator()

    var body: some Scene {
        #if !os(macOS) && !targetEnvironment(macCatalyst)
        DocumentGroupLaunchScene("Sprite Pencil", backgroundStyle: Color.yellow) {
            NewDocumentButton("New Sprite", for: SpriteImageDocument.self) {
                try await withCheckedThrowingContinuation { continuation in
                    documentCreationContinuation = continuation
                    isTemplatePickerPresented = true
                }
            }
            .alert("Event Intro", isPresented: $appCoordinator.showingAppStoreEvent) {
                Button("OK", role: .close) { }
            } message: {
                Text("Now let's celebrate by opening a new sprite and using the new tools!")
            }
            // `onDismiss` catches the swipe-down that skips the picker's own
            // buttons; without it the continuation leaks and `NewDocumentButton`
            // never becomes tappable again.
            .sheet(isPresented: $isTemplatePickerPresented, onDismiss: {
                documentCreationContinuation?.resume(throwing: DocumentCreationError.userCancelled)
                documentCreationContinuation = nil
            }) {
                TemplatePickerView { selectedSize in
                    guard let selectedSize else {
                        documentCreationContinuation?.resume(throwing: DocumentCreationError.userCancelled)
                        documentCreationContinuation = nil
                        isTemplatePickerPresented = false
                        return
                    }

                    documentCreationContinuation?.resume(returning: SpriteImageDocument(size: selectedSize))
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

        DocumentGroup(newDocument: SpriteImageDocument(size: .defaultSize)) { file in
            EditorView(document: file.$document)
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
        }
    }

}
