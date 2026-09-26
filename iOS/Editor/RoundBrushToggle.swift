import SwiftUI

struct RoundBrushToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: isOn ? "circle.fill" : "square.fill")
        }
        .help("Round Brush")
    }
}

#Preview {
    RoundBrushToggle(isOn: .constant(true))
}
