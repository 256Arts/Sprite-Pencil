import Foundation
import PaletteKit
import SpritePencilKit

// PaletteKit is the shared, storage-agnostic palette model; the editor paints in 8-bit sRGB.
// Both modules spell a palette `Palette`, so this is the only file that imports both: it qualifies
// each side and hands the rest of the app plain SpritePencilKit types.

/// The space PaletteKit's fractions are realized in on the way here. Pixel palettes are plain sRGB,
/// so this only picks the intermediate representation — every space round-trips the same bytes.
private let bridgingColorSpace = PaletteKit.ColorSpace.okLch

extension SpritePencilKit.Palette {

    /// The palette selected when the user has chosen none.
    static var defaultPremadeName: String { PaletteKit.Palette.defaultPremadeName }

    /// The premade palettes to offer on `date` — the year-round set, with a seasonal palette
    /// (Valentine's Day, May the 4th, Pride, October, December) promoted to the top when in season.
    static func handpicked(on date: Date = .now) -> [SpritePencilKit.Palette] {
        PaletteKit.Palette.handpickedPalettes(on: date, colorSpace: bridgingColorSpace).map { SpritePencilKit.Palette($0) }
    }

    /// Fetches the palette a `lospec-palette://<slug>` URL points to.
    static func lospec(_ url: URL) async throws -> SpritePencilKit.Palette {
        SpritePencilKit.Palette(try await PaletteKit.Palette.lospec(url, colorSpace: bridgingColorSpace))
    }

    convenience init(_ palette: PaletteKit.Palette) {
        self.init(
            name: palette.name,
            specialCase: nil,
            colors: palette.colors.map { ColorComponents($0) },
            defaultGroupLength: palette.defaultGroupLength,
            groupLengths: palette.groupLengths ?? [])
    }
}

extension ColorComponents {

    /// A shared palette color realized as the opaque 8-bit sRGB the editor paints with.
    init(_ color: PaletteKit.PaletteColor) {
        let srgb = color.srgb8(colorSpace: bridgingColorSpace)
        self.init(red: srgb.red, green: srgb.green, blue: srgb.blue, opacity: 255)
    }
}

extension SpritePencilKit.Palette {

    /// A function snapping any color to this palette's perceptually nearest color (smallest ΔE₀₀),
    /// keeping the input's opacity. The palette is converted to Lab once, up front, so the function
    /// is cheap to run once per distinct canvas color. Returns the input unchanged if the palette is empty.
    func nearestColorMatcher() -> (ColorComponents) -> ColorComponents {
        func paletteColor(_ color: ColorComponents) -> PaletteKit.PaletteColor? {
            PaletteKit.PaletteColor(sRGB8BitRed: Int(color.red), green: Int(color.green), blue: Int(color.blue), colorSpace: bridgingColorSpace)
        }
        let candidates = colors.filter { paletteColor($0) != nil }
        let matcher = PaletteKit.NearestColorMatcher(candidates.compactMap(paletteColor), colorSpace: bridgingColorSpace)
        return { color in
            guard let index = paletteColor(color).flatMap(matcher.nearestIndex(to:)) else { return color }
            let nearest = candidates[index]
            return ColorComponents(red: nearest.red, green: nearest.green, blue: nearest.blue, opacity: color.opacity)
        }
    }
}
