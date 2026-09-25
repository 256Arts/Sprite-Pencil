import SpritePencilKit
import SwiftUI
import UIKit

/// Deterministic demo state for App Store screenshots, switched on by the `-screenshotMode` launch
/// argument the UI test passes.
///
/// There is no store to seed here: the app opens onto the document browser, and what a shot of that
/// would show is whatever sprites happen to be in the person's iCloud Drive. So the seed is a
/// *document* — the sprite `demoSprite` picks for the device — and `ScreenshotApp` hands it straight to
/// the editor. Nothing is written to disk and nothing the person owns is photographed.
enum ScreenshotMode {

    /// Whether this launch is a screenshot run. Read by `SpritePencilAppLauncher` before either app
    /// is built.
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshotMode")
    }

    /// The Mac window to photograph, in points.
    ///
    /// Chosen to leave a margin inside the runner's 2560x1600 canvas at 2x. Catalyst has no
    /// `Scene.defaultSize`, so `ScreenshotApp` pins it through the window scene's size restrictions.
    static let macWindowSize = CGSize(width: 1180, height: 760)

    /// The demo document's title, which is the window title on the Mac.
    @MainActor
    static var documentName: String { demoSprite.name }

    /// Puts the app into its screenshot state. Stands in for `SpritePencilApp.init()`, so none of
    /// that app's launch side effects (the app-group flag, the iCloud Drive folder) happen here.
    @MainActor
    static func prepare() {
        UserDefaults.standard.register()
        pinDefaults()
        // Only the palettes the app ships. The person's own palettes live in `Documents/Palettes`
        // and would otherwise be in the palette-picker shot.
        PaletteStore.shared.loadPalettes(includingUserPalettes: false)
        report("ready — pinned defaults, no store to seed; demo sprite \"\(documentName)\", \(PaletteStore.shared.allPalettes.count) shipped palettes")
    }

    // MARK: - Saying what happened

    /// What this launch prepared, in one line, for the walk and for the shared runner.
    ///
    /// A failed walk otherwise reports only "seeded content never appeared", which is equally true
    /// of defaults that never got pinned, a screen that never opened, and an identifier renamed
    /// last week. The walk reads this out of the accessibility tree before its first shot and
    /// prints it on any miss, and the fixed prefix makes it greppable in the build log.
    @MainActor private(set) static var status = "the seed has not run"

    @MainActor private static func report(_ line: String) {
        status = line
        print("SCREENSHOT MODE: \(line)")
    }

    /// The editor's document for this run: the demo sprite, with no file behind it.
    @MainActor
    static func makeDocument() -> SpriteImageDocument {
        SpriteImageDocument(data: demoSpritePNG())
    }

    // MARK: - Settings

    /// Fixes the settings the shots depend on, for this launch only.
    ///
    /// They go into the *argument* domain rather than being saved: that domain outranks the app's
    /// stored preferences, so a run is deterministic even on a Mac the app has really been used on,
    /// and it lives only in memory, so the run doesn't overwrite them.
    @MainActor
    private static func pinDefaults() {
        let defaults = UserDefaults.standard
        var domain = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        // `handpicked()` rotates a seasonal palette to the top, so naming the year-round default is
        // what keeps the palette grid the same in June and in October.
        domain[UserDefaults.Key.colorPalette] = Palette.defaultPremadeName
        domain[UserDefaults.Key.currentColor] = demoSprite.color
        domain[UserDefaults.Key.showPixelGrid] = true
        domain[UserDefaults.Key.showTileGrid] = false
        domain[UserDefaults.Key.showTiledPreview] = false
        domain[UserDefaults.Key.canvasBackgroundColor] = CanvasBackground.default.rawValue
        // The document is new, so this warning wouldn't appear anyway; pinned so a shot can never
        // be an alert if that ever changes.
        domain[UserDefaults.Key.showPermanentEditWarning] = false
        domain[UserDefaults.Key.autosaveEnabled] = true
        // `setVolatileDomain` refuses to replace a domain that already exists, and the argument
        // domain always does.
        defaults.removeVolatileDomain(forName: UserDefaults.argumentDomain)
        defaults.setVolatileDomain(domain, forName: UserDefaults.argumentDomain)
    }

    // MARK: - Demo sprite

    /// The sprite each shot shows: the small apple fits an iPhone screen at a readable zoom; the
    /// larger duck scene fills the room an iPad, Mac, or Vision Pro canvas has.
    private struct DemoSprite {
        /// The window title on the Mac.
        let name: String
        /// A data set in `Preview Assets`, copied from `Raw Assets`. Development assets, so archives
        /// leave them out: only a screenshot run reads them.
        let asset: String
        /// The color the editor opens with — one of the sprite's own, so the color well in the tool
        /// bar matches it rather than showing whatever was last painted with.
        let color: String
    }

    @MainActor
    private static var demoSprite: DemoSprite {
        UIDevice.current.userInterfaceIdiom == .phone
            ? DemoSprite(name: "Apple", asset: "Screenshot Apple", color: "E43B44")
            : DemoSprite(name: "Duck", asset: "Screenshot Duck", color: "F3DD3C")
    }

    /// The demo sprite as PNG bytes, which is what `SpriteImageDocument` holds.
    @MainActor
    private static func demoSpritePNG() -> Data {
        NSDataAsset(name: demoSprite.asset)!.data
    }
}

extension View {

    /// Carries `ScreenshotMode.status` into the accessibility tree, where the walk reads it.
    ///
    /// Nothing on a normal launch; on a screenshot run, a one-point transparent label — present to
    /// XCUITest, invisible in the shot. It is how the walk can tell a seed that never ran from a
    /// screen that never opened, neither of which the app can report any other way: a simulator
    /// app's `print` does not reach the build log, and there is no file path both the app and the
    /// runner can write.
    @MainActor
    @ViewBuilder
    func screenshotModeStatus() -> some View {
        if ScreenshotMode.isActive {
            overlay(alignment: .topLeading) {
                Text(ScreenshotMode.status)
                    .font(.system(size: 1))
                    .opacity(0.001)
                    .accessibilityIdentifier("ScreenshotMode.Status")
                    .allowsHitTesting(false)
            }
        } else {
            self
        }
    }
}
