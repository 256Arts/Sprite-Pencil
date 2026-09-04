import XCTest

/// Drives the app through the screens that become App Store screenshots and attaches each one to the
/// result bundle, where the shared `screenshots` runner collects them.
///
/// One test rather than one per screen: the shots are a walk through a single launch, and splitting
/// them would pay the launch — and the reseed — every time.
@MainActor
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    func testCaptureAppStoreScreenshots() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-screenshotMode"]
        app.launch()
        // The Mac run is driven from a terminal, which stays frontmost otherwise — and clicks into a
        // window that is not key land nowhere.
        app.activate()

        // The palette inspector's "Recent" section is filled from the sprite's own pixels once the
        // drawing context loads, so it appears only after the seeded document is really on screen.
        let recentColors = app.staticTexts["Recent"]
        XCTAssertTrue(recentColors.waitForExistence(timeout: 60), "seeded content never appeared")
        settle()
        capture("01-editor")

        activate(control("Eraser"), "the eraser tool")
        settle()
        capture("99-diagnostic")

        activate(toolbarItem("Settings"), "Settings")
        settle()
        capture("03-settings")
        activate(control("Done"), "Settings' Done button")

        activate(control("Choose Palette"), "the palette chooser")
        settle()
        capture("02-palettes")
        activate(control("Done"), "the palette chooser's Done button")

        activate(toolbarItem("Canvas"), "the Canvas menu")
        settle()
        capture("04-canvas")
    }

    // MARK: - Driving

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
            return XCTFail("never found \(description)")
        }
        #if targetEnvironment(macCatalyst)
        // Catalyst builds against the iOS SDK, so `click()` does not exist — and a plain `tap()`
        // misses some small SwiftUI controls there (the inspector's palette pencil among them).
        // Clicking the element's own center hits them.
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        #else
        element.tap()
        #endif
    }

    /// Animations and async content have no element to wait on, so the shots pause instead.
    private func settle(seconds: TimeInterval = 2) {
        Thread.sleep(forTimeInterval: seconds)
    }

    // MARK: - Capturing

    private func capture(_ name: String) {
        #if os(macOS) || targetEnvironment(macCatalyst) || os(visionOS)
        // Both of these are photographed from outside the test: the Mac by `screencapture -l`, and
        // visionOS by `simctl io screenshot` (its `XCUIScreen.main.screenshot()` comes back 1x1).
        requestExternalCapture(named: name)
        #else
        // The simulator's screen already *is* the store's canvas, at the exact required pixel size.
        attach(XCTAttachment(screenshot: XCUIScreen.main.screenshot()), named: name)
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
