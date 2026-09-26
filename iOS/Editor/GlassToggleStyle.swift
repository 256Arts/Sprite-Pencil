import SwiftUI

/// A circular glass button that fills with the accent while on. `.toggleStyle(.button)`
/// ignores the glass style and border shape on Mac, drawing a square bezel instead.
struct GlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        if configuration.isOn {
            Button {
                configuration.isOn.toggle()
            } label: {
                configuration.label
            }
            .buttonStyle(.glassProminent)
            .tint(.yellowAccent)
            .foregroundStyle(.black)
        } else {
            Button {
                configuration.isOn.toggle()
            } label: {
                configuration.label
            }
            .buttonStyle(.glass)
        }
    }
}
