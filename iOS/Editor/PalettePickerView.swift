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
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(store.userPalettes) { palette in
                        Button {
                            selectPalette(palette)
                        } label: {
                            PalettePreview(palette: palette, selectedPaletteName: $selectedPaletteName)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deletePalette(palette)
                            }
                        }
                        .contextMenu {
                            Button("Delete", systemImage: "trash") {
                                deletePalette(palette)
                            }
                        }
                    }
                    .reorderable()
                }
                Text("Handpicked")
                    .font(.headline)
                ForEach(handpickedPalettes) { palette in
                    Button {
                        selectPalette(palette)
                    } label: {
                        PalettePreview(palette: palette, selectedPaletteName: $selectedPaletteName)
                    }
                    .buttonStyle(.plain)
                }
                Text("Basic")
                    .font(.headline)
                ForEach(basicPalettes) { palette in
                    Button {
                        selectPalette(palette)
                    } label: {
                        PalettePreview(palette: palette, selectedPaletteName: $selectedPaletteName)
                    }
                    .buttonStyle(.plain)
                }
            }
            .reorderContainer(for: Palette.self) { difference in
                var palettes = store.userPalettes
                difference.apply(to: &palettes)
                store.setUserPalettes(palettes)
            }
            .swipeActionsContainer()
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
        .alert("Failed To Load Palette", isPresented: $showingImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Palette images must have a height of 1px, and not contain clear pixels.")
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

extension ReorderDifference where CollectionID == ReorderableSingleCollectionIdentifier {
    /// Applies a single-collection drag-to-reorder result in one in-place pass.
    func apply<C>(to collection: inout C)
        where C: RangeReplaceableCollection,
              C.Element: Identifiable,
              C.Element.ID == ItemID {
        let moving = Set(sources)
        guard !moving.isEmpty else { return }

        var moved: [C.Element] = []
        moved.reserveCapacity(moving.count)
        collection.removeAll { element in
            guard moving.contains(element.id) else { return false }
            moved.append(element)
            return true
        }

        switch destination.position {
        case .before(let id):
            let index = collection.firstIndex { $0.id == id } ?? collection.endIndex
            collection.insert(contentsOf: moved, at: index)
        case .end:
            collection.append(contentsOf: moved)
        }
    }
}

#Preview {
    PalettePickerView(selectedPaletteName: "", onSelect: { _ in })
}
