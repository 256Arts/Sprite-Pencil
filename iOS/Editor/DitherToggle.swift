import SwiftUI

struct DitherToggle: View {
    
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Image(systemName: "checkerboard.rectangle")
        }
        .toggleStyle(GlassToggleStyle())
        .help("Dithering Mode")
        .keyboardShortcut("D")
    }
}

#Preview {
    DitherToggle(isOn: .constant(true))
}
