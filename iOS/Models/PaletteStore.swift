import UIKit
import SpritePencilKit

/// The app's palette catalog: user palettes stored as PNGs in
/// `Documents/Palettes/`, the handpicked palettes PaletteKit ships (seasonally
/// rotated, bridged in `PaletteBridge`), and the kit's built-in specials.
/// Replaces the old mutable statics on `Palette`, so palette lists are
/// observable and main-actor isolated.
@MainActor @Observable
final class PaletteStore {

    static let shared = PaletteStore()

    private(set) var userPalettes: [Palette] = []
    private(set) var handpickedPalettes: [Palette] = []
    private(set) var defaultPalette = Palette.sp16

    var allPalettes: [Palette] {
        userPalettes + handpickedPalettes + [.sp16, .rrggbb, .hhhhssbb, .rrrgggbb]
    }

    func palette(named name: String) -> Palette? {
        allPalettes.first { $0.name == name }
    }

    // MARK: - Loading

    func loadPalettes() {
        loadUserPalettes()
        loadHandpickedPalettes()
    }

    private func loadUserPalettes() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: userPalettesDirectoryURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                let name = fileURL.deletingPathExtension().lastPathComponent
                if let image = UIImage(contentsOfFile: fileURL.path), let palette = Palette(name: name, image: image, defaultGroupLength: 1) {
                    userPalettes.append(palette)
                } else {
                    print("Failed to load user palette")
                }
            }
        } catch {
            print("Did not find user palettes directory")
        }
        applyPersistedOrder()
    }

    private func loadHandpickedPalettes() {
        handpickedPalettes = Palette.handpicked()
        defaultPalette = palette(named: Palette.defaultPremadeName) ?? .sp16
    }

    // MARK: - User palettes

    /// Saves a palette to the user's collection, uniquifying its name
    /// ("My Palette 2") so two same-named imports can't collide as
    /// `Identifiable` IDs or overwrite each other's PNG on disk.
    func add(_ palette: Palette) {
        let name = uniqueName(for: palette.name)
        let named = name == palette.name ? palette : Palette(name: name, specialCase: palette.specialCase, colors: palette.colors, defaultGroupLength: palette.defaultGroupLength, groupLengths: palette.groupLengths)
        userPalettes.append(named)

        do {
            try FileManager.default.createDirectory(at: userPalettesDirectoryURL, withIntermediateDirectories: true)
            guard let data = named.pngData() else { return }
            try data.write(to: fileURL(forPaletteNamed: named.name))
        } catch {
            print("Failed to write palette file or directory: \(error)")
        }
        persistOrder()
    }

    func delete(_ palette: Palette) {
        guard let index = userPalettes.firstIndex(of: palette) else { return }
        userPalettes.remove(at: index)
        do {
            try FileManager.default.removeItem(at: fileURL(forPaletteNamed: palette.name))
        } catch {
            print("Failed to delete user palette: \(error)")
        }
        persistOrder()
    }

    /// Replaces the user-palette order (e.g. after a drag-to-reorder) and
    /// persists it. Filesystem enumeration order isn't stable, so the chosen
    /// order is stored by name and re-applied on the next launch.
    func setUserPalettes(_ palettes: [Palette]) {
        userPalettes = palettes
        persistOrder()
    }

    // MARK: - Order persistence

    private func persistOrder() {
        UserDefaults.standard.set(userPalettes.map(\.name), forKey: UserDefaults.Key.userPaletteOrder)
    }

    private func applyPersistedOrder() {
        guard let order = UserDefaults.standard.stringArray(forKey: UserDefaults.Key.userPaletteOrder) else { return }
        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        // Stable sort by saved rank; palettes not in the saved order (newly
        // added on another device, imported since) sort to the end.
        userPalettes.sort { (rank[$0.name] ?? Int.max) < (rank[$1.name] ?? Int.max) }
    }

    private var userPalettesDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Palettes", isDirectory: true)
    }

    private func fileURL(forPaletteNamed name: String) -> URL {
        userPalettesDirectoryURL.appendingPathComponent(name, isDirectory: false).appendingPathExtension("png")
    }

    private func uniqueName(for name: String) -> String {
        let taken = Set(allPalettes.map(\.name))
        guard taken.contains(name) else { return name }
        var counter = 2
        while taken.contains("\(name) \(counter)") { counter += 1 }
        return "\(name) \(counter)"
    }

}
