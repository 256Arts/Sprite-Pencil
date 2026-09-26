import XCTest

/// Drives the app through the screens that become App Store screenshots and attaches each one to the
/// result bundle, where the shared `screenshots` runner collects them.
///
/// One test rather than one per screen: the shots are a walk through a single launch, and splitting
/// them would pay the launch — and the reseed — every time.
@MainActor
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    /// Whether the walk turned the device on its side, which the capture has to undo.
    ///
    /// Tracked here rather than read back from `XCUIDevice.shared.orientation`, which a simulator
    /// answers as portrait however the UI is laid out.
    private var isLandscape = false

    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-screenshotMode"]
        app.launch()
        // The Mac run is driven from a terminal, which stays frontmost otherwise — and the Mac shot
        // is of the frontmost window.
        app.activate()
        #if os(iOS)
        turnToRequestedOrientation()
        #endif

        checkSeedIsThrowaway()
        // The palette inspector's "Recent" section is filled from the sprite's own pixels once the
        // drawing context loads, so it appears only after the seeded document is really on screen.
        waitFor(app.staticTexts["Recent"], "the palette inspector's Recent section", shot: "01-editor")
        settle()
        capture("01-editor")

        #if !targetEnvironment(macCatalyst)
        // Mac Catalyst stops at the editor: XCUITest's synthesized clicks and keystrokes reach a
        // Catalyst app and do nothing, so the walk can't open anything there.

        // Before Settings: at compact width the inspector is a sheet, and Settings' sheet
        // replaces it.
        activate(control("Choose Palette"), "the palette chooser")
        settle()
        capture("02-palettes")
        activate(control("Done"), "the palette chooser's Done button")

        activate(toolbarItem("Settings"), "Settings")
        settle()
        capture("03-settings")
        activate(control("Done"), "Settings' Done button")

        activate(toolbarItem("Canvas"), "the Canvas menu")
        settle()
        capture("04-canvas")
        #endif
    }

    // MARK: - The seed

    /// What the app said it prepared, read out of the accessibility tree.
    ///
    /// The app hangs `ScreenshotMode.status` on its root view (`.screenshotModeStatus()`). A walk
    /// that cannot find it is running against a build that has not adopted that modifier, which is
    /// worth saying plainly rather than reporting as an empty seed.
    private var seedStatus: String {
        let label = app.descendants(matching: .any)["ScreenshotMode.Status"]
        guard label.waitForExistence(timeout: 30) else {
            return "no ScreenshotMode.Status element — add .screenshotModeStatus() to the app's root view"
        }
        // A SwiftUI `Text` reaches XCUITest as the element's *value* on macOS and as its *label* on
        // iOS, so take whichever is filled in rather than betting on one.
        if let value = label.value as? String, !value.isEmpty { return value }
        return label.label
    }

    /// Stops the walk when the app did not report a ready state.
    ///
    /// `ScreenshotMode.prepare` reports what it pinned and seeded before the first shot. A walk that
    /// missed that would then photograph an unprepared app and fail on a missing element, which says
    /// nothing about why. Read the reason instead, before the first shot.
    private func checkSeedIsThrowaway() {
        let status = seedStatus
        print("SCREENSHOT MODE: \(status)")
        guard status.hasPrefix("ready") else {
            attach(XCTAttachment(string: app.debugDescription), named: "element-tree")
            return XCTFail("the app did not report a ready state, so there is nothing to photograph — \(status)")
        }
    }

    private static var platform: String {
        #if targetEnvironment(macCatalyst)
        "Mac Catalyst"
        #elseif os(visionOS)
        "visionOS"
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
        #endif
    }

    /// Which simulator this was, for a failure read days after the run's own log is gone.
    private static var device: String {
        ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "this machine"
    }

    // MARK: - Driving

    /// Waits for `element` to exist, and on a miss names the platform, the device, what it was
    /// waiting for, and `seedStatus` — so a failure explains itself instead of reporting only
    /// "seeded content never appeared".
    private func waitFor(_ element: XCUIElement, _ description: String, shot: String, timeout: TimeInterval = 60) {
        guard element.waitForExistence(timeout: timeout) else {
            attach(XCTAttachment(string: app.debugDescription), named: "element-tree")
            return XCTFail("""
                \(shot): never found \(description) in \(Int(timeout))s on \(Self.platform), \(Self.device).
                The app reported: \(seedStatus)
                """)
        }
    }

    /// Finds a toolbar item, opening the bar's overflow menu first if that is where it ended up.
    ///
    /// The editing and sharing groups carry `.visibilityPriority(.low)`, so at compact width — every
    /// iPhone — they are not in the bar at all but behind its "More" button.
    private func toolbarItem(_ label: String) -> XCUIElement {
        let item = control(label)
        if item.exists { return item }
        activate(control("More"), "the toolbar's overflow menu")
        return control(label)
    }

    /// Tabs, menus, and toolbar items surface as different element types per platform — a menu is a
    /// `Button` on iOS and a `MenuButton` on the Mac — so look through the types that can actually be
    /// activated rather than guessing one.
    private func control(_ label: String) -> XCUIElement {
        // Matched on either, because a SwiftUI `Button("Canvas", systemImage:)` carries its title
        // as an accessibility *label* while a test-only identifier would land in `identifier`.
        let named = NSPredicate(format: "identifier == %@ OR label == %@", label, label)
        // Searched across every element type rather than a list of likely ones: the same control is
        // a Button on iOS, a MenuButton or a Toggle on the Mac, and a MenuItem once it is inside an
        // open menu. Not `firstMatch`, which short-circuits resolution and can report
        // `exists == false` while an indexed lookup finds the very same element.
        return app.descendants(matching: .any).matching(named).element(boundBy: 0)
    }

    private func activate(_ element: XCUIElement, _ description: String) {
        guard element.waitForExistence(timeout: 15) else {
            attach(XCTAttachment(string: app.debugDescription), named: "missed-\(description)")
            return XCTFail("""
                never found \(description) on \(Self.platform), \(Self.device).
                The app reported: \(seedStatus)
                """)
        }
        element.tap()
    }

    #if os(iOS)
    /// Turns the device the way the runner asked (`IPAD_ORIENTATION`, landscape by default on iPad).
    ///
    /// After `launch()`, not before: a rotation set before the app is up is silently dropped, and
    /// the set comes back portrait. The runner checks every shot's shape, so that fails the run.
    private func turnToRequestedOrientation() {
        guard ProcessInfo.processInfo.environment["SCREENSHOT_ORIENTATION"] == "landscape" else { return }
        XCUIDevice.shared.orientation = .landscapeLeft
        isLandscape = true
        settle()
    }
    #endif

    /// Animations and async content have no element to wait on, so the shots pause instead.
    private func settle(seconds: TimeInterval = 2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capturing

    private func capture(_ name: String) {
        // Every capture below photographs the whole screen, or the frontmost window — never this
        // app in particular. So an app that has lost the foreground yields another app's UI, filed
        // under this app's name, at the right size, with nothing to notice. The shared runner holds
        // a machine-wide lock so that cannot happen; this is the check that it held.
        XCTAssertEqual(app.state, .runningForeground,
                       "\(name): the app under test was not frontmost — another app has this device")
        #if os(macOS) || targetEnvironment(macCatalyst) || os(visionOS)
        // Both of these are photographed from outside the test: the Mac by `screencapture -l`, and
        // visionOS by `simctl io screenshot` (its `XCUIScreen.main.screenshot()` comes back 1x1).
        requestExternalCapture(named: name)
        #else
        // The simulator's screen already *is* the store's canvas, at the exact required pixel size.
        attach(upright(XCUIScreen.main.screenshot()), named: name)
        #endif
    }

    /// The screenshot, turned the way the device is being held.
    ///
    /// `XCUIScreen.main.screenshot()` photographs the *physical* screen: a rotated device comes back
    /// as a portrait buffer carrying its quarter turn as metadata, which `XCTAttachment(screenshot:)`
    /// writes out content-on-its-side. Redrawing bakes the metadata into the pixels — `UIImage.size`
    /// is already the turned size and `draw(at:)` honours the orientation, so no manual rotation.
    private func upright(_ screenshot: XCUIScreenshot) -> XCTAttachment {
        #if os(iOS)
        guard isLandscape else { return XCTAttachment(screenshot: screenshot) }
        let image = screenshot.image
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale   // keep the pixel count the store checks against
        format.opaque = true
        return XCTAttachment(image: UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(at: .zero)
        })
        #else
        XCTAttachment(screenshot: screenshot)
        #endif
    }

    private func attach(_ attachment: XCTAttachment, named name: String) {
        attachment.name = name
        attachment.lifetime = .keepAlways   // attachments on a passing test are discarded otherwise
        add(attachment)
    }

    #if os(macOS) || targetEnvironment(macCatalyst) || os(visionOS)

    /// Asks the shell running the tests to take the picture, and waits for it.
    ///
    /// On the Mac the good capture is `screencapture -l`, which reads the window's own buffer:
    /// correctly masked to the rounded corners, with real alpha and the system's own shadow. It
    /// needs Screen Recording, which the test runner has no grant for and the terminal running the
    /// script does. So the test drives the UI and the script takes the picture.
    ///
    /// They meet in a plain directory under /tmp, which works only because the runner is
    /// deliberately unsandboxed (UITests.entitlements): a sandboxed runner cannot write /tmp, and
    /// its own container is unreadable to the script, so the two would have nowhere to meet.
    private static let handshakeDirectory = URL(fileURLWithPath: "/tmp/app-store-screenshots")

    private func requestExternalCapture(named name: String) {
        let files = FileManager.default
        let handshake = Self.handshakeDirectory
        let done = handshake.appendingPathComponent("done-\(name)")
        try? files.removeItem(at: done)

        let request = handshake.appendingPathComponent("request-\(name)")
        guard files.createFile(atPath: request.path, contents: nil) else {
            return XCTFail("could not write a capture request to \(request.path)")
        }

        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if files.fileExists(atPath: done.path) { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTFail("timed out waiting for the script to capture \(name) — is the runner watching \(handshake.path)?")
    }

    #endif
}
