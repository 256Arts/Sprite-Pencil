import SwiftUI
import SpritePencilKit

@Observable
final class PaletteCollectionController {
    var palette: Palette?
    var recentColors: [ColorComponents] = []
    var showClearColor: Bool = false
    var messagesAppMode: Bool = false
    let maxRecentColorCount: Int = 16

    func usedColor(components: ColorComponents) {
        guard components.opacity == 255 else { return }
        if let idx = recentColors.firstIndex(of: components) {
            if idx != 0 {
                let moved = recentColors.remove(at: idx)
                recentColors.insert(moved, at: 0)
            }
            return
        }
        if recentColors.count >= maxRecentColorCount {
            recentColors.removeLast()
        }
        recentColors.insert(components, at: 0)
    }
}

struct PaletteCollectionView: View {
    var controller: PaletteCollectionController

    #if targetEnvironment(macCatalyst)
    var itemMinLength: CGFloat = 20
    var itemMaxLength: CGFloat = 30
    #else
    var itemMinLength: CGFloat = 30
    var itemMaxLength: CGFloat = 42
    #endif
    
    let showPaletteChooserButton: Bool
    let spacing: CGFloat = 8
    
    @Binding var selectedColor: ColorComponents
    
    @State private var showingPaletteChooser = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !controller.messagesAppMode {
                    if !controller.recentColors.isEmpty {
                        Text("Recent")
                            .font(.headline)
                        
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: itemMinLength, maximum: itemMaxLength))],
                            spacing: spacing
                        ) {
                            ForEach(controller.recentColors, id: \.self) { color in
                                ColorCell(
                                    components: color,
                                    isSelected: color == selectedColor
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                            }
                        }
                    }
                    
                    if let palette = controller.palette {
                        HStack {
                            Text(palette.name)
                                .font(.headline)
                            
                            if showPaletteChooserButton {
                                Button("Choose Palette", systemImage: "pencil") {
                                    self.showingPaletteChooser = true
                                }
                                .buttonStyle(.borderless)
                                .labelStyle(.iconOnly)
                                .help("Choose Palette")
                            }
                        }
                        
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: itemMinLength, maximum: itemMaxLength))],
                            spacing: spacing
                        ) {
                            ForEach(palette.colors, id: \.self) { color in
                                ColorCell(
                                    components: color,
                                    isSelected: color == selectedColor
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                            }
                        }
                    }
                    
                    if controller.showClearColor {
                        Text("Clear")
                            .font(.headline)
                        
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: itemMinLength, maximum: itemMaxLength))],
                            spacing: spacing
                        ) {
                            ColorCell(
                                components: .clear,
                                isSelected: selectedColor == .clear
                            )
                            .onTapGesture {
                                selectedColor = .clear
                            }
                        }
                    }
                } else if let palette = controller.palette {
                    // messagesAppMode == true
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: itemMinLength, maximum: itemMaxLength))],
                        spacing: spacing
                    ) {
                        ForEach(palette.colors, id: \.self) { color in
                            ColorCell(
                                components: color,
                                isSelected: color == selectedColor
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                        }
                    }
                }
            }
            .scenePadding()
        }
        .sheet(isPresented: $showingPaletteChooser) {
            NavigationStack {
                PalettePickerView(selectedPaletteName: controller.palette?.name ?? "", onSelect: { palette in
                    controller.palette = palette
                })
            }
        }
        .tint(.yellowAccent)
    }
}

private struct ColorCell: View {
    var components: ColorComponents
    var isSelected: Bool

    private var uiColor: UIColor {
        UIColor(red: CGFloat(components.red) / 255.0,
                green: CGFloat(components.green) / 255.0,
                blue: CGFloat(components.blue) / 255.0,
                alpha: CGFloat(components.opacity) / 255.0)
    }

    private var swiftUIColor: Color {
        Color(uiColor)
    }

    private var isVeryDarkColor: Bool {
        components.red < 30 && components.green < 30 && components.blue < 30
    }

    private var borderColor: Color {
        isSelected ? Color(UIColor(named: "AccentColor") ?? .label) : Color.clear
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(swiftUIColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .inset(by: -4)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                
                if isVeryDarkColor {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(UIColor.opaqueSeparator), lineWidth: 0.5)
                }
            }
    }
}
