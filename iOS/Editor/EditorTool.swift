//
//  EditorTool.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer.
//  Copyright © 2026 256 Arts Developer. All rights reserved.
//

import SpritePencilKit
import SwiftUI

/// The drawing tools shown in the editor's bottom bar, in display order.
///
/// Centralizes everything that used to be addressed by a bare tool *index*: the
/// button order and labels, plus how each case maps onto the kit's tool structs
/// held by `DocumentController`.
enum EditorTool: Int, CaseIterable, Identifiable {
    case pencil, eraser, fill, move, highlight, shadow, eyedropper

    var id: Int { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .pencil: "Brush"
        case .eraser: "Eraser"
        case .fill: "Bucket"
        case .move: "Move"
        case .highlight: "Highlight"
        case .shadow: "Shadow"
        case .eyedropper: "Eyedropper"
        }
    }

    var icon: Image {
        switch self {
        case .pencil: Image(.brush)
        case .eraser: Image(.eraser)
        case .fill: Image(.bucket)
        case .move: Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
        case .highlight: Image(.highlight)
        case .shadow: Image(.shadow)
        case .eyedropper: Image(systemName: "eyedropper")
        }
    }

    /// The kit tool instance this case selects, fetched from `controller`.
    @MainActor func tool(in controller: DocumentController) -> Tool {
        switch self {
        case .pencil: controller.pencilTool
        case .eraser: controller.eraserTool
        case .fill: controller.fillTool
        case .move: controller.moveTool
        case .highlight: controller.highlightTool
        case .shadow: controller.shadowTool
        case .eyedropper: controller.eyedroperTool
        }
    }

    /// The width-adjustable tool backing this case, or `nil` for tools with no
    /// brush width (fill, move, eyedropper) — which hides the width stepper.
    @MainActor func sizableTool(in controller: DocumentController) -> (any SizableTool)? {
        switch self {
        case .pencil: controller.pencilTool
        case .eraser: controller.eraserTool
        case .highlight: controller.highlightTool
        case .shadow: controller.shadowTool
        default: nil
        }
    }

    /// Sets `width` (clamped to the tool's own max) on this case's backing tool
    /// and makes it the controller's active tool. Writing the width back to the
    /// stored struct is what restores it when the user returns to this tool;
    /// assigning `controller.tool` pushes the new size to the canvas via its
    /// `didSet`. No-op for tools with no brush width (fill, move, eyedropper).
    @MainActor func setWidth(_ width: Int, in controller: DocumentController) {
        func apply<T: SizableTool>(_ keyPath: ReferenceWritableKeyPath<DocumentController, T>) {
            controller[keyPath: keyPath].width = min(width, controller[keyPath: keyPath].maxWidth)
            controller.tool = controller[keyPath: keyPath]
        }
        switch self {
        case .pencil: apply(\.pencilTool)
        case .eraser: apply(\.eraserTool)
        case .highlight: apply(\.highlightTool)
        case .shadow: apply(\.shadowTool)
        default: break
        }
    }
}
