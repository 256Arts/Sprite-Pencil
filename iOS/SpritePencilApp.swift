import SwiftUI
import UIKit
import SpritePencilKit
import StoreKit
import UniformTypeIdentifiers

@Observable
final class AppCoordinator: NSObject {

    var importingPaletteFromLospec: Palette? = nil
    var showingAppStoreEvent = false

    func handleIncoming(url: URL) {
        if url.isFileURL {
            // No-op for file URLs in this refactor. Previously would present the document.
        } else if url.path().contains("spritepencil/appstoreevent") {
            showingAppStoreEvent = true
        } else {
            handleCustomURL(url: url)
        }
    }

    func handleBrowsingWeb(activity: NSUserActivity) {
        if activity.activityType == NSUserActivityTypeBrowsingWeb, let incomingURL = activity.webpageURL {
            importSpriteFromAppGroup(userActivityURL: incomingURL)
        }
    }

    func handleCustomURL(url: URL) {
        if url.scheme == "spritepencil" && url.host == "importfromapp" {
            importSpriteFromAppGroup(userActivityURL: nil)
        } else {
            openLospecURL(url)
        }
    }

    func importSpriteFromAppGroup(userActivityURL: URL?) {
        guard userActivityURL == nil || userActivityURL?.path == "/spritepencil/importfromapp" else {
            print("unknown user activity URL")
            return
        }
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SpritePencilApp.spritePencilAppGroupID) else { return }
        let importSpriteImageURL = containerURL.appendingPathComponent("Import").appendingPathExtension("png")
        guard let imageData = try? Data(contentsOf: importSpriteImageURL) else { return }

        let appGroupDefaults = UserDefaults(suiteName: SpritePencilApp.spritePencilAppGroupID)
        let preferedFileName = appGroupDefaults?.string(forKey: "importSpriteName")

        var url = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        url.appendPathComponent(preferedFileName ?? NSLocalizedString("Sprite", comment: "Default image name"))
        url.appendPathExtension("png")
//        let document = Document(fileURL: url)
//        document.fileData = imageData
//        document.save(to: url, for: .forCreating) { (saveSuccess) in
//            guard saveSuccess else {
//                print("Unable to save new document.")
//                return
//            }
//            document.close(completionHandler: { (closeSuccess) in
//                guard closeSuccess else {
//                    print("Unable to close new document.")
//                    return
//                }
//            })
//        }
    }

    struct LospecPalette: Codable {
        let name: String
        let author: String
        let colors: [String]
    }

    func openLospecURL(_ url: URL) {
        guard url.scheme == "lospec-palette", let paletteSlug = url.host else { return }
        
        guard let jsonURL = URL(string: "https://lospec.com/palette-list/\(paletteSlug).json") else { return }
        let task = URLSession.shared.dataTask(with: jsonURL) { (data, response, error) in
            print(error as Any)
            guard let data = data else { return }
            do {
                let lospecPalette = try JSONDecoder().decode(LospecPalette.self, from: data)
                let colorComps = lospecPalette.colors.map({ ColorComponents(hex: $0) })
                guard let colors = colorComps as? [ColorComponents] else { return }
                let palette = Palette(name: lospecPalette.name, specialCase: nil, colors: colors, defaultGroupLength: 1)

                DispatchQueue.main.async {
                    // Set observable state to drive a SwiftUI sheet
                    self.importingPaletteFromLospec = palette
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }
}

@main
struct SpritePencilApp: App {
    
    enum DocumentCreationError: Error {
        case userCancelled
    }
    
    static let spritePencilAppGroupID =  "group.com.jaydenirwin.spritepencil"

    init() {
        UserDefaults.standard.register()
        Self.loadAppPalettes()

        let appGroupDefaults = UserDefaults(suiteName: Self.spritePencilAppGroupID)
        appGroupDefaults?.set(true, forKey: "ownsSpritePencil")

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
            .sheet(isPresented: $isTemplatePickerPresented) {
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

    private static func loadAppPalettes() {
        struct PaletteConfig { let name: String; let defaultGroupLength: Int }

        do {
            let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Palettes", isDirectory: true)
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
            for fileURL in fileURLs {
                let name = fileURL.deletingPathExtension().lastPathComponent
                if let image = UIImage(contentsOfFile: fileURL.path), let palette = Palette(name: name, image: image, defaultGroupLength: 1) {
                    Palette.userPalettes.append(palette)
                } else {
                    print("Failed to load user palette")
                }
            }
        } catch {
            print("Did not find user palettes directory")
        }

        var configs = [
            PaletteConfig(name: "Island Joy 16", defaultGroupLength: 1),
            PaletteConfig(name: "PICO-8", defaultGroupLength: 1),
            PaletteConfig(name: "Zughy 32", defaultGroupLength: 5),
            PaletteConfig(name: "Endesga 32", defaultGroupLength: 4),
            PaletteConfig(name: "BLK 36", defaultGroupLength: 6),
            PaletteConfig(name: "Apollo", defaultGroupLength: 6),
            PaletteConfig(name: "Endesga 64", defaultGroupLength: 6),
            PaletteConfig(name: "SPF-80", defaultGroupLength: 1)
        ]
        let month = Calendar.current.component(.month, from: Date())
        let day = Calendar.current.component(.day, from: Date())
        switch month {
        case 2:
            if day == 14 { configs.insert(PaletteConfig(name: "Hearts", defaultGroupLength: 2), at: 0) }
        case 5:
            if day == 4 { configs.insert(PaletteConfig(name: "TIE Fighter", defaultGroupLength: 1), at: 0) }
        case 6:
            configs.insert(PaletteConfig(name: "Pride", defaultGroupLength: 1), at: 0)
        case 10:
            configs.insert(PaletteConfig(name: "HallowPumpkin", defaultGroupLength: 1), at: 0)
        case 12:
            configs.insert(PaletteConfig(name: "POLA5", defaultGroupLength: 1), at: 0)
        default:
            break
        }

        for config in configs {
            if let image = UIImage(named: config.name), let palette = Palette(name: config.name, image: image, defaultGroupLength: config.defaultGroupLength) {
                Palette.handpickedPalettes.append(palette)
                if config.name == "Endesga 32" { Palette.defaultPalette = palette }
            }
        }

        let buildingBricks = Palette(name: "Building Bricks", specialCase: nil, colors: {
            let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [
                (242,243,242),(230,227,224),(160,165,169),(99,95,97),(5,19,29),(242,205,55),(201,26,9),(114,14,15),
                (180,210,227),(90,147,219),(0,85,191),(10,52,99),(75,159,74),(35,120,65),(24,70,50),(88,42,18),
                (53,33,0),(7,139,201),(169,85,0),(149,138,115),(125,191,221),(250,156,28),(208,145,104),(224,255,176),
                (187,233,11),(246,215,179),(194,218,184),(249,186,97),(254,186,189),(201,202,226),(146,57,120),(204,112,42),
                (115,220,161),(63,54,145),(199,210,60),(255,167,11),(254,138,24),(242,112,94),(96,116,161),(160,188,172),
                (132,94,132),(228,205,158),(0,143,155),(67,84,163)
            ]
            return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, opacity: 255) })
        }(), defaultGroupLength: 1)
        Palette.handpickedPalettes.insert(buildingBricks, at: 5)
    }
}

extension Palette: Identifiable {
    public var id: String { name }
}
