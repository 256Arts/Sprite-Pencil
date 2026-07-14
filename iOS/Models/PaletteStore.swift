import UIKit
import SpritePencilKit

/// The app's palette catalog: user palettes stored as PNGs in
/// `Documents/Palettes/`, bundled handpicked palettes (seasonally rotated),
/// and the kit's built-in specials. Replaces the old mutable statics on
/// `Palette`, so palette lists are observable and main-actor isolated.
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
        struct PaletteConfig { let name: String; let defaultGroupLength: Int }

        var configs = [
            PaletteConfig(name: "Island Joy 16", defaultGroupLength: 1),
            PaletteConfig(name: "PICO-8", defaultGroupLength: 1),
            PaletteConfig(name: "Zughy 32", defaultGroupLength: 5),
            PaletteConfig(name: "Endesga 32", defaultGroupLength: 4),
            PaletteConfig(name: "BLK 36", defaultGroupLength: 6),
            PaletteConfig(name: "Apollo", defaultGroupLength: 6),
            PaletteConfig(name: "Endesga 64", defaultGroupLength: 6),
            PaletteConfig(name: "SPF-80", defaultGroupLength: 1)
        ]
        let month = Calendar.current.component(.month, from: Date())
        let day = Calendar.current.component(.day, from: Date())
        switch month {
        case 2:
            if day == 14 { configs.insert(PaletteConfig(name: "Hearts", defaultGroupLength: 2), at: 0) }
        case 5:
            if day == 4 { configs.insert(PaletteConfig(name: "TIE Fighter", defaultGroupLength: 1), at: 0) }
        case 6:
            configs.insert(PaletteConfig(name: "Pride", defaultGroupLength: 1), at: 0)
        case 10:
            configs.insert(PaletteConfig(name: "HallowPumpkin", defaultGroupLength: 1), at: 0)
        case 12:
            configs.insert(PaletteConfig(name: "POLA5", defaultGroupLength: 1), at: 0)
        default:
            break
        }

        for config in configs {
            if let image = UIImage(named: config.name), let palette = Palette(name: config.name, image: image, defaultGroupLength: config.defaultGroupLength) {
                handpickedPalettes.append(palette)
                if config.name == "Endesga 32" { defaultPalette = palette }
            }
        }

        let buildingBricks = Palette(name: "Building Bricks", specialCase: nil, colors: {
            let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [
                (242,243,242),(230,227,224),(160,165,169),(99,95,97),(5,19,29),(242,205,55),(201,26,9),(114,14,15),
                (180,210,227),(90,147,219),(0,85,191),(10,52,99),(75,159,74),(35,120,65),(24,70,50),(88,42,18),
                (53,33,0),(7,139,201),(169,85,0),(149,138,115),(125,191,221),(250,156,28),(208,145,104),(224,255,176),
                (187,233,11),(246,215,179),(194,218,184),(249,186,97),(254,186,189),(201,202,226),(146,57,120),(204,112,42),
                (115,220,161),(63,54,145),(199,210,60),(255,167,11),(254,138,24),(242,112,94),(96,116,161),(160,188,172),
                (132,94,132),(228,205,158),(0,143,155),(67,84,163)
            ]
            return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, opacity: 255) })
        }(), defaultGroupLength: 1)
        handpickedPalettes.insert(buildingBricks, at: min(5, handpickedPalettes.count))
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
