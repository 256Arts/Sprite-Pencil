import SwiftUI

struct ToolSelectionButtonToggleStyle: ToggleStyle {

    /// A circle rather than the tool bar's capsule, for standalone option toggles.
    var circular = false

    private var width: CGFloat { circular ? 38 : 48 }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            // An explicit platter size, so every button matches whatever its icon
            // (a `.glassProminent` platter hugs the label plus padding).
            configuration.label
                .frame(width: circular ? 32 : 42, height: 32)
                .foregroundStyle(configuration.isOn ? AnyShapeStyle(.black) : AnyShapeStyle(.primary))
                .selectionPlatter(configuration.isOn, in: circular ? AnyShape(.circle) : AnyShape(.capsule))
                .contentShape(circular ? AnyShape(.circle) : AnyShape(.capsule))
        }
        .buttonStyle(.plain)
        .frame(width: width, height: 38)
    }
}

struct ToolSelectionBar: View {

    @Binding var selectedTool: EditorTool

    var body: some View {
        HStack {
            ToolSelectionButtons(selectedTool: $selectedTool)
                .toggleStyle(ToolSelectionButtonToggleStyle())
                .labelStyle(.iconOnly)
                .padding(.horizontal, -2)
        }
        .padding(2)
        .platterGlass()
    }
}

extension View {

    /// The glass platter behind a row of controls. visionOS has no `glassEffect`; its windows' own
    /// glass is the equivalent.
    func platterGlass() -> some View {
        #if os(visionOS)
        glassBackgroundEffect(in: .capsule)
        #else
        glassEffect()
        #endif
    }

    /// A yellow platter marking the selected button, clear otherwise.
    fileprivate func selectionPlatter(_ isOn: Bool, in shape: AnyShape) -> some View {
        #if os(visionOS)
        background(isOn ? AnyShapeStyle(Color.yellowAccent) : AnyShapeStyle(.clear), in: shape)
            .hoverEffect()
        #else
        glassEffect(isOn ? .regular.tint(.yellowAccent).interactive() : .identity, in: shape)
        #endif
    }
}

/// The buttons are separated into their own view in case we want to show them in a `.toolbar` in the future
struct ToolSelectionButtons: View {

    @Binding var selectedTool: EditorTool

    var body: some View {
        ForEach(EditorTool.allCases) { tool in
            Toggle(isOn: Binding(get: {
                selectedTool == tool
            }, set: { isOn in
                if isOn { selectedTool = tool }
            })) {
                Label { Text(tool.title) } icon: {
                    // Only affects the SF Symbols (Move, Eyedropper), which otherwise
                    // look small beside the bitmap tool icons.
                    tool.icon.imageScale(.large)
                }
            }
        }
    }
}

#Preview {
    ToolSelectionButtons(selectedTool: .constant(.pencil))
}
