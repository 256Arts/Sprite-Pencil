import SwiftUI

/// The app a screenshot run gets: the real editor, on `ScreenshotMode`'s demo sprite, in a plain
/// window.
///
/// The shipping app opens onto the document browser, so its first screen is the person's own iCloud
/// Drive and the editor is only reachable by picking a file out of it — neither deterministic nor
/// worth photographing. Everything below the scene is the shipping editor, unmodified.
struct ScreenshotApp: App {

    @State private var document = ScreenshotMode.makeDocument()

    init() {
        ScreenshotMode.prepare()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                EditorView(document: document)
                    .navigationTitle(ScreenshotMode.documentName)
            }
            #if targetEnvironment(macCatalyst)
            .onAppear {
                // The runner clears saved Mac window frames with `defaults`, which resolves a
                // sandboxed app's domain to its container and so finds nothing to clear here. Left
                // alone, the window would come up at whatever size it was last dragged to, and that
                // is the size every Mac shot would be. Size restrictions are the one lever the app
                // itself has.
                for case let windowScene as UIWindowScene in UIApplication.shared.connectedScenes {
                    windowScene.sizeRestrictions?.minimumSize = ScreenshotMode.macWindowSize
                    windowScene.sizeRestrictions?.maximumSize = ScreenshotMode.macWindowSize
                }
            }
            #endif
        }
    }
}
