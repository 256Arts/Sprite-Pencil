//
//  PalettePreviewView.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2021-03-01.
//  Copyright © 2021 256 Arts Developer. All rights reserved.
//

import SwiftUI
import SpritePencilKit

struct PalettePreview: View {
    
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
        .background(palette.name == selectedPaletteName ? Color.yellowAccent : Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
}

#Preview {
    PalettePreview(palette: Palette.sp16, selectedPaletteName: .constant(Palette.sp16.name))
}
