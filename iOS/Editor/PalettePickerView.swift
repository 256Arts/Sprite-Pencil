//
//  PalettePickerView.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2021-03-01.
//  Copyright © 2021 256 Arts Developer. All rights reserved.
//

import SwiftUI
import SpritePencilKit

struct PalettePickerView: View, DropDelegate {
    
    let handpickedPalettes: [Palette] = {
        var palettes = Palette.handpickedPalettes
        palettes.insert(Palette.sp16, at: 2)
        return palettes
    }()
    let basicPalettes = [Palette.rrggbb, Palette.hhhhssbb, Palette.rrrgggbb]
    
    @Environment(\.dismiss) var dismiss
    @AppStorage(UserDefaults.Key.colorPalette) private var colorPaletteName: String = ""
    
    @State var selectedPaletteName: String
    @State var userPaletteCount = Palette.userPalettes.count
    @State var showingImportError = false
    
    let onSelect: (Palette) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Your Palettes")
                    .font(.headline)
                if userPaletteCount == 0 {
                    Text("Drop palette images here.")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                } else {
                    ForEach(Palette.userPalettes, id: \.name) { palette in
                        PalettePreview(palette: palette, selectedPaletteName: $selectedPaletteName)
                            .onTapGesture {
                                selectPalette(palette)
                            }
                            .contextMenu {
                                Button("Delete", systemImage: "trash") {
                                    deletePalette(palette)
                                }
                            }
                    }
                }
                Text("Handpicked")
                    .font(.headline)
                ForEach(handpickedPalettes, id: \.name) { palette in
                    PalettePreview(palette: palette, selectedPaletteName: $selectedPaletteName)
                        .onTapGesture {
                            selectPalette(palette)
                        }
                }
                Text("Basic")
                    .font(.headline)
                ForEach(basicPalettes, id: \.name) { palette in
                    PalettePreview(palette: palette, selectedPaletteName: $selectedPaletteName)
                        .onTapGesture {
                            selectPalette(palette)
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Palettes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") {
                    dismiss()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color(UIColor.systemGroupedBackground))
        .onDrop(of: [.image], delegate: self)
        .alert(isPresented: $showingImportError) { () -> Alert in
            Alert(title: Text("Failed To Load Palette"), message: Text("Palette images must have a height of 1px, and not contain clear pixels."))
        }
        .tint(.yellowAccent)
    }
    
    func userPalette(at index: Int) -> Palette {
        if Palette.userPalettes.indices.contains(index) {
            Palette.userPalettes[index]
        } else {
            Palette.sp16
        }
    }
    
    func selectPalette(_ palette: Palette) {
        onSelect(palette)
        selectedPaletteName = palette.name
        colorPaletteName = palette.name
    }
    
    func deletePalette(_ palette: Palette) {
        guard let index = Palette.userPalettes.firstIndex(of: palette) else { return }
        userPaletteCount -= 1
        let removed = Palette.userPalettes.remove(at: index)
        
        if removed.name == selectedPaletteName {
            selectPalette(Palette.defaultPalette)
        }
        
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Palettes", isDirectory: true)
        let imageURL = directoryURL.appendingPathComponent(removed.name, isDirectory: false).appendingPathExtension("png")
        do {
            try FileManager.default.removeItem(at: imageURL)
        } catch {
            print("Failed to delete user palette")
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        if let itemProvider = info.itemProviders(for: [.image]).first {
            itemProvider.loadObject(ofClass: UIImage.self) { item, error in
                guard let image = item as? UIImage else { return }
                let name = itemProvider.suggestedName ?? NSLocalizedString("My Palette", comment: "default palette name")
                if let palette = Palette(name: name, image: image, defaultGroupLength: 1) {
                    Palette.addPalette(palette, paletteImage: image)
                    userPaletteCount += 1
                } else {
                    showingImportError = true
                }
            }
        } else {
            return false
        }
        return true
    }
    
}

#Preview {
    PalettePickerView(selectedPaletteName: "", onSelect: { _ in })
}
