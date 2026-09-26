import SwiftUI

struct RoundBrushToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: isOn ? "circle.fill" : "square.fill")
                .imageScale(.large)
        }
        .buttonStyle(.borderless)
        .buttonBorderShape(.circle)
        .tint(.primary)
        .frame(width: 38, height: 38)
        .help("Round Brush")
    }
}

#Preview {
    RoundBrushToggle(isOn: .constant(true))
}
