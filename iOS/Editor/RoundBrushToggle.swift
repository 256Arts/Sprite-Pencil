import SwiftUI

struct RoundBrushToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: isOn ? "circle.fill" : "square.fill")
            #if targetEnvironment(macCatalyst)
                .imageScale(.large)
            #endif
        }
        .help("Round Brush")
    }
}

#Preview {
    RoundBrushToggle(isOn: .constant(true))
}
