//
//  AddPaletteView.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2020-05-19.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import SpritePencilKit

struct AddPaletteView: View {

    @Environment(\.dismiss) private var dismiss
    
    @State var palette: Palette
    @State var name = ""
    @State var fromLospec: Bool
    
    var paletteImage: UIImage?
    var completionHandler: ((Bool) -> Void)?
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Image(decorative: "Palette Colored")
                Text("Add Palette")
                    .font(Font.system(size: 32, weight: .bold, design: .default))
                if self.fromLospec {
                    Text("from lospec.com")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name:")
                        .font(.headline)
                    TextField("Name", text: $name)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(6)
                }
                Spacer()
                Button {
                    let namedPalette = Palette(
                        name: name,
                        specialCase: palette.specialCase,
                        colors: palette.colors,
                        defaultGroupLength: palette.defaultGroupLength,
                        groupLengths: palette.groupLengths
                    )
                    Palette.addPalette(namedPalette, paletteImage: self.paletteImage)
                    self.completionHandler?(true)
                    dismiss()
                } label: {
                    Text("Add Palette")
                        .frame(width: 300)
                }
                #if os(visionOS)
                .buttonStyle(.borderedProminent)
                #else
                .buttonStyle(.glassProminent)
                #endif
                .controlSize(.large)
                .disabled(name.isEmpty)
            }
                .frame(width: 300)
                .padding(.vertical, 64)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") {
                            self.completionHandler?(false)
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    AddPaletteView(palette: Palette(name: "My Palette", specialCase: nil, colors: [], defaultGroupLength: 1), fromLospec: true)
}
