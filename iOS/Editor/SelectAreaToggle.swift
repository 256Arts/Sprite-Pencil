import SwiftUI

struct SelectAreaToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Image(systemName: "rectangle.dashed")
                .imageScale(.large)
        }
        .toggleStyle(ToolSelectionButtonToggleStyle(circular: true))
        .help("Select Area")
    }
}

#Preview {
    SelectAreaToggle(isOn: .constant(true))
}
