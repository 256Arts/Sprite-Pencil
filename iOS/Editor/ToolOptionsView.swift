//
//  ToolOptionsView.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2020-05-16.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import SpritePencilKit

struct ToolOptionsView: View {
    
    // MARK: - State supplied by parent (EditorView)
    @Binding var currentBrushWidth: Int?
    @Binding var ditherOn: Bool
    @Binding var roundBrush: Bool

    /// Largest brush width the current tool allows (varies per tool).
    var maxBrushWidth: Int = 10

    // Color accessors supplied by parent
    var colorGet: () -> Color
    var colorSet: (Color) -> Void

    var body: some View {
        // The `ToolOptionsView` is usually aligned to the trailing edge,
        // so to reduce controls moving around, put optional controls on the leading edge.
        if self.currentBrushWidth != nil {
            // The brush shape only matters once the brush is large enough to
            // have a meaningful curve (3px+); below that it's always a solid block.
            if 3 <= (self.currentBrushWidth ?? 1) {
                RoundBrushToggle(isOn: Binding(get: { self.roundBrush }, set: { self.roundBrush = $0 }))
                    .buttonStyle(.glass)
            }

            LabeledStepper(min: 1, max: maxBrushWidth, value: Binding<Int>(
                get: { self.currentBrushWidth ?? 1 },
                set: { newValue in self.currentBrushWidth = newValue }
            ))

            DitherToggle(isOn: Binding(get: { self.ditherOn }, set: { self.ditherOn = $0 }))
                .buttonStyle(.glass)
        }
        
        ColorPicker("Color", selection: Binding(get: {
            colorGet()
        }, set: { newValue in
            colorSet(newValue)
        }))
        .labelsHidden()
        .frame(maxWidth: 32, maxHeight: 32)
    }
}

#Preview {
    ToolOptionsView(
        currentBrushWidth: .constant(1),
        ditherOn: .constant(false),
        roundBrush: .constant(false),
        colorGet: { .red },
        colorSet: { _ in }
    )
}
