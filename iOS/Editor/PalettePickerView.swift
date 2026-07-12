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

    let basicPalettes = [Palette.rrggbb, Palette.hhhhssbb, Palette.rrrgggbb]

    @Environment(\.dismiss) var dismiss
    @AppStorage(UserDefaults.Key.colorPalette) private var colorPaletteName: String = ""

    @State var selectedPaletteName: String
    @State var showingImportError = false

    let onSelect: (Palette) -> Void

    private var store: PaletteStore { .shared }

    private var handpickedPalettes: [Palette] {
        var palettes = store.handpickedPalettes
        palettes.insert(Palette.sp16, at: min(2, palettes.count))
        return palettes
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Your Palettes")
                    .font(.headline)
                if store.userPalettes.isEmpty {
                    Text("Drop palette images here.")
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                } else {
                    ForEach(store.userPalettes) { palette in
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
                ForEach(handpickedPalettes) { palette in
                    PalettePreview(palette: palette, selectedPaletteName: $selectedPaletteName)
                        .onTapGesture {
                            selectPalette(palette)
                        }
                }
                Text("Basic")
                    .font(.headline)
                ForEach(basicPalettes) { palette in
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

    func selectPalette(_ palette: Palette) {
        onSelect(palette)
        selectedPaletteName = palette.name
        colorPaletteName = palette.name
    }

    func deletePalette(_ palette: Palette) {
        store.delete(palette)
        if palette.name == selectedPaletteName {
            selectPalette(store.defaultPalette)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.image]).first else { return false }
        itemProvider.loadObject(ofClass: UIImage.self) { item, error in
            guard let image = item as? UIImage else { return }
            let name = itemProvider.suggestedName ?? NSLocalizedString("My Palette", comment: "default palette name")
            // `loadObject` completes on an arbitrary queue; the store and the
            // alert flag are main-actor.
            Task { @MainActor in
                if let palette = Palette(name: name, image: image, defaultGroupLength: 1) {
                    store.add(palette)
                } else {
                    showingImportError = true
                }
            }
        }
        return true
    }

}

#Preview {
    PalettePickerView(selectedPaletteName: "", onSelect: { _ in })
}
