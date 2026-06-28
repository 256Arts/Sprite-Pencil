//
//  FingerAction.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer.
//  Copyright © 2026 256 Arts Developer. All rights reserved.
//

import SpritePencilKit
import SwiftUI

/// App-side presentation for the kit's `CanvasUIView.FingerAction`.
///
/// Centralizes the finger-action setting that used to be a bare string shared
/// between `SettingsView` (the picker) and `EditorView` (the canvas wiring), the
/// same way `CanvasBackground` does for the checkerboard. The `rawValue` is the
/// value persisted under `UserDefaults.Key.fingerAction`.
extension CanvasUIView.FingerAction {

    /// The non-drawing finger behaviors a user can choose in Settings. `.draw`
    /// is omitted: it's the implicit behavior when pencil-only drawing is off,
    /// not a user-selectable option.
    static let userSelectableCases: [Self] = [.move, .eyedrop, .ignore]

    var displayName: LocalizedStringKey {
        switch self {
        case .draw: "Draw"
        case .move: "Move"
        case .eyedrop: "Eyedrop"
        case .ignore: "Ignore"
        }
    }
}
