import SwiftUI

struct DitherToggle: View {
    
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Image(systemName: "checkerboard.rectangle")
                .imageScale(.large)
        }
        // Same look as the tool bar's buttons, which it sits beside.
        .toggleStyle(ToolSelectionButtonToggleStyle())
        .help("Dithering Mode")
        .keyboardShortcut("D")
    }
}

#Preview {
    DitherToggle(isOn: .constant(true))
}
