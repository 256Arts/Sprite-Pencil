import Foundation

/// The app group shared by the main app, the Messages extension, and the
/// widget — the hand-off surface for sprites and widget configuration.
enum AppGroup {

    static let id = "group.com.jaydenirwin.spritepencil"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: id)
    }

    /// Keys in the group's `UserDefaults`.
    enum Key {
        /// PNG data of the sprite the widget displays.
        static let sprite = "sprite"
        /// Hex color drawn behind the widget's sprite.
        static let backgroundColor = "backgroundColor"
        /// Preferred filename for a sprite handed off by another app.
        static let importSpriteName = "importSpriteName"
        /// Set at launch so sibling apps can detect Sprite Pencil is installed.
        static let ownsSpritePencil = "ownsSpritePencil"
    }

}
