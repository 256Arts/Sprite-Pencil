import SwiftUI

/// The bucket's global mode: a tap recolors every pixel of the tapped color,
/// not just the region around it.
struct ReplaceAllToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Image(systemName: "circle.grid.3x3.fill")
            #if targetEnvironment(macCatalyst)
                .imageScale(.large)
            #endif
        }
        .help("Replace All Matching Colors")
    }
}

#Preview {
    ReplaceAllToggle(isOn: .constant(true))
}
