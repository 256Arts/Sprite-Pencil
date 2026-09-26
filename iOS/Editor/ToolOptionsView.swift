import SwiftUI
import SpritePencilKit

struct ToolOptionsView: View {
    
    // MARK: - State supplied by parent (EditorView)
    @Binding var currentBrushWidth: Int?
    @Binding var ditherOn: Bool
    @Binding var roundBrush: Bool

    /// Largest brush width the current tool allows (varies per tool).
    var maxBrushWidth: Int = 10

    /// Non-nil only while the move tool is active; shows the select-area toggle.
    var selectAreaOn: Binding<Bool>?

    /// Non-nil only while the bucket is active; shows the replace-all toggle.
    var replaceAllOn: Binding<Bool>?

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
                    .toolOptionButtonStyle()
            }

            LabeledStepper(min: 1, max: maxBrushWidth, value: Binding<Int>(
                get: { self.currentBrushWidth ?? 1 },
                set: { newValue in self.currentBrushWidth = newValue }
            ))
            .toolOptionGlass()

            DitherToggle(isOn: Binding(get: { self.ditherOn }, set: { self.ditherOn = $0 }))
                .toolOptionToggleStyle()
        }

        if let selectAreaOn {
            SelectAreaToggle(isOn: selectAreaOn)
                .toolOptionToggleStyle(circular: true)
        }

        if let replaceAllOn {
            ReplaceAllToggle(isOn: replaceAllOn)
                .toolOptionToggleStyle(circular: true)
        }

        ColorPicker("Color", selection: Binding(get: {
            colorGet()
        }, set: { newValue in
            colorSet(newValue)
        }))
        .labelsHidden()
        .fixedSize()
    }
}

// On iPhone and iPad each tool option floats on its own glass. On Mac and visionOS
// they share one platter (see `EditorView.trailingBottomBarItems`), so they draw
// like the tool bar's buttons instead.
extension View {

    func toolOptionButtonStyle() -> some View {
        #if targetEnvironment(macCatalyst) || os(visionOS)
        buttonStyle(.borderless)
            .buttonBorderShape(.circle)
            .tint(.primary)
            .frame(width: 38, height: 38)
        #else
        buttonStyle(.glass)
        #endif
    }

    func toolOptionToggleStyle(circular: Bool = false) -> some View {
        #if targetEnvironment(macCatalyst) || os(visionOS)
        toggleStyle(ToolSelectionButtonToggleStyle(circular: circular))
        #else
        toggleStyle(.button).buttonStyle(.glass)
        #endif
    }

    func toolOptionGlass() -> some View {
        #if targetEnvironment(macCatalyst) || os(visionOS)
        self
        #else
        glassEffect(.regular)
        #endif
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
