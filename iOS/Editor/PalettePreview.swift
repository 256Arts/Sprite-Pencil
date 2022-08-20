//
//  PalettePreviewView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2021-03-01.
//  Copyright © 2021 Jayden Irwin. All rights reserved.
//

import SwiftUI
import SpritePencilKit

extension ColorComponents: Identifiable {
    public var id: UUID {
        UUID()
    }
}

struct PalettePreview: View {
    
    weak var editorDetailVC: EditorDetailViewController!
    
    @State var palette: Palette
    @Binding var selectedPaletteName: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(palette.colors.prefix(16)) { color in
                    Rectangle()
                        .foregroundColor(Color(components: color))
                }
            }
            .frame(height: 16)
            HStack {
                Text(palette.name)
                    .foregroundColor(palette.name == selectedPaletteName ? Color(UIColor.darkText) : Color(UIColor.label))
                Spacer()
                Text("\(palette.colors.count)")
                    .foregroundColor(palette.name == selectedPaletteName ? Color(UIColor.darkText) : Color(UIColor.secondaryLabel))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(palette.name == selectedPaletteName ? Color.accentColor : Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onTapGesture {
            selectPalette(palette)
        }
    }
    
    func selectPalette(_ palette: Palette) {
        editorDetailVC.documentController.palette = palette
        selectedPaletteName = palette.name
        UserDefaults.standard.set(palette.name, forKey: UserDefaults.Key.colorPalette)
        editorDetailVC.paletteCollectionVC.loadPalette(palette)
    }
    
}

struct PalettePreview_Previews: PreviewProvider {
    static var previews: some View {
        PalettePreview(palette: Palette.sp16, selectedPaletteName: .constant(Palette.sp16.name))
    }
}
