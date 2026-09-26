import SwiftUI

struct ToolSelectionButtonToggleStyle: ToggleStyle {

    /// A circle rather than the tool bar's capsule, for standalone option toggles.
    var circular = false

    private var width: CGFloat { circular ? 38 : 48 }

    func makeBody(configuration: Configuration) -> some View {
        if configuration.isOn {
            Button {
                configuration.isOn.toggle()
            } label: {
                // Fill the frame so the platter is the same size whatever the icon;
                // otherwise it hugs the label, and short SF Symbols get a short platter.
                configuration.label
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.glassProminent)
            // Match the capsule platter; Mac otherwise draws a rounded rectangle.
            .buttonBorderShape(circular ? .circle : .capsule)
            .tint(.yellowAccent)
            .foregroundStyle(.black)
            .frame(width: width, height: 38)
        } else {
            Button {
                configuration.isOn.toggle()
            } label: {
                configuration.label
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(circular ? .circle : .capsule)
            .tint(.primary)
            .frame(width: width, height: 38)
        }
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
        .glassEffect()
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
