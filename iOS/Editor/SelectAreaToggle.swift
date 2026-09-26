import SwiftUI

struct SelectAreaToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Image(systemName: "rectangle.dashed")
        }
        .toggleStyle(GlassToggleStyle())
        .help("Select Area")
    }
}

#Preview {
    SelectAreaToggle(isOn: .constant(true))
}
