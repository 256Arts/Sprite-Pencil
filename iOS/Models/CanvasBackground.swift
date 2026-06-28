//
//  CanvasBackground.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer.
//  Copyright © 2026 256 Arts Developer. All rights reserved.
//

import UIKit
import SwiftUI

/// The checkerboard backdrop drawn behind a sprite's transparent pixels.
///
/// Centralizes the canvas-background setting that used to be a bare string shared
/// between `SettingsView` (the picker) and `EditorView` (the two checker colors).
/// The `rawValue` is the value persisted under `UserDefaults.Key.canvasBackgroundColor`.
enum CanvasBackground: String, CaseIterable, Identifiable {
    case `default`, white, pink, green

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .default: "Default"
        case .white: "White"
        case .pink: "Pink"
        case .green: "Green"
        }
    }

    /// The two alternating colors of the checkerboard: `base` for one square,
    /// `alternate` for its neighbor.
    var checkerColors: (base: UIColor, alternate: UIColor) {
        switch self {
        case .default: (.systemGray4, .systemGray5)
        case .white: (UIColor(white: 1.0, alpha: 1.0), UIColor(white: 0.93, alpha: 1.0))
        case .pink: (.systemPink, .systemPink.withAlphaComponent(0.9))
        case .green: (.systemGreen, .systemGreen.withAlphaComponent(0.9))
        }
    }
}
