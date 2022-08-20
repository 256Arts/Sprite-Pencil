//
//  PalettePickerView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2021-03-01.
//  Copyright © 2021 Jayden Irwin. All rights reserved.
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
    
    weak var editorDetailVC: EditorDetailViewController!
    
    @Environment(\.dismiss) var dismiss
    
    @State var selectedPaletteName = Palette.sp16.name
    @State var userPaletteCount = Palette.userPalettes.count
    @State var showingImportError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    Text("Your Palettes")
                        .font(.headline)
                    if userPaletteCount == 0 {
                        Text("Drop palette images here.")
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    } else {
                        ForEach(0..<userPaletteCount) { index in
                            PalettePreview(editorDetailVC: editorDetailVC, palette: userPalette(at: index), selectedPaletteName: $selectedPaletteName)
                                .contextMenu {
                                    Button {
                                        deletePalette(userPalette(at: index))
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    Text("Handpicked")
                        .font(.headline)
                    ForEach(handpickedPalettes, id: \.name) { palette in
                        PalettePreview(editorDetailVC: editorDetailVC, palette: palette, selectedPaletteName: $selectedPaletteName)
                    }
                    Text("Basic")
                        .font(.headline)
                    ForEach(basicPalettes, id: \.name) { palette in
                        PalettePreview(editorDetailVC: editorDetailVC, palette: palette, selectedPaletteName: $selectedPaletteName)
                    }
                }
                .padding()
            }
            .navigationTitle("Palettes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                        editorDetailVC.presentedViewController?.dismiss(animated: true, completion: nil)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .onDrop(of: [.image], delegate: self)
        .onAppear() {
            selectedPaletteName = editorDetailVC.documentController.palette?.name ?? Palette.sp16.name
        }
        .alert(isPresented: $showingImportError) { () -> Alert in
            Alert(title: Text("Failed To Load Palette"), message: Text("Palette images must have a height of 1px, and not contain clear pixels."))
        }
    }
    
    func userPalette(at index: Int) -> Palette {
        if Palette.userPalettes.indices.contains(index) {
            return Palette.userPalettes[index]
        } else {
            return Palette.sp16
        }
    }
    
    func selectPalette(_ palette: Palette) {
        editorDetailVC.documentController.palette = palette
        selectedPaletteName = palette.name
        UserDefaults.standard.set(palette.name, forKey: UserDefaults.Key.colorPalette)
        editorDetailVC.paletteCollectionVC.loadPalette(palette)
    }
    
    func deletePalette(_ palette: Palette) {
        guard let index = Palette.userPalettes.firstIndex(of: palette) else { return }
        userPaletteCount -= 1
        let removed = Palette.userPalettes.remove(at: index)
        
        if removed == editorDetailVC.documentController.palette {
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

struct PalettePickerView_Previews: PreviewProvider {
    static var previews: some View {
        PalettePickerView()
    }
}
