import SwiftUI
import SpritePencilKit

struct PalettePreview: View {
    
    @State var palette: Palette
    @Binding var selectedPaletteName: String
    /// Set when this is the palette the open sprite is drawn with (or nearly).
    var imageMatch: PaletteMatch.Kind? = nil

    private var isSelected: Bool { palette.name == selectedPaletteName }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(palette.colors.prefix(16)) { color in
                    Rectangle()
                        .foregroundStyle(Color(components: color))
                }
            }
            .frame(height: 16)
            HStack {
                Text(palette.name)
                    .foregroundStyle(isSelected ? Color(UIColor.darkText) : Color(UIColor.label))
                if let imageMatch {
                    Text(imageMatch == .exact ? "Matches Image" : "Closest Match")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? Color(UIColor.darkText) : Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isSelected ? AnyShapeStyle(.black.opacity(0.1)) : AnyShapeStyle(.fill.tertiary), in: .capsule)
                }
                Spacer()
                Text("\(palette.colors.count)")
                    .foregroundStyle(isSelected ? Color(UIColor.darkText) : Color(UIColor.secondaryLabel))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(isSelected ? Color.yellowAccent : Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
    
}

#Preview {
    PalettePreview(palette: Palette.sp16, selectedPaletteName: .constant(Palette.sp16.name))
}
