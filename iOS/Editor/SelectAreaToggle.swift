import SwiftUI

struct SelectAreaToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Image(systemName: "rectangle.dashed")
            #if targetEnvironment(macCatalyst)
                .imageScale(.large)
            #endif
        }
        .toggleStyle(.button)
        .help("Select Area")
    }
}

#Preview {
    SelectAreaToggle(isOn: .constant(true))
}
