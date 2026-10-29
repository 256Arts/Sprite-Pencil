import UIKit
import SpritePencilKit

/// The palette an opened sprite appears to be drawn with, so the palette picker can point it out.
struct PaletteMatch: Equatable, Sendable {

    enum Kind: Sendable {
        /// The palette contains every color in the sprite.
        case exact
        /// No palette contains them all, but this one comes close.
        case closest
    }

    let paletteName: String
    let kind: Kind

    /// Fewer colors than this say little about the palette (most palettes share black and white);
    /// more than this and it's a photo or painting, not palette-constrained pixel art.
    private static let meaningfulColorCounts = 3...256

    /// The mean ΔE₀₀ a palette may be off by and still be called the closest match. ~2 is a
    /// just-noticeable difference; up to ~6 is recognizably the same set of colors.
    private static let closestMatchMaxDistance = 6.0

    /// Finds the palette `image` was drawn with. Prefers `current` when it fits exactly, otherwise
    /// the smallest palette that does — the tightest fit is the likeliest source. Generated palettes
    /// (RRGGBB and co.) are skipped: they cover so much that they'd match almost anything.
    ///
    /// Scans every pixel and compares colors perceptually, so call it off the main actor.
    static func find(for image: UIImage, among palettes: [Palette], preferring current: Palette?) -> PaletteMatch? {
        guard let colors = distinctOpaqueColors(in: image, limit: meaningfulColorCounts.upperBound),
              meaningfulColorCounts.contains(colors.count) else { return nil }
        let candidates = palettes.filter { $0.specialCase == nil }

        let exact = candidates.filter { colors.isSubset(of: $0.colors) }
        if let palette = exact.first(where: { $0 == current }) ?? exact.min(by: { $0.colors.count < $1.colors.count }) {
            return PaletteMatch(paletteName: palette.name, kind: .exact)
        }

        let imageColors = Array(colors)
        let closest = candidates
            .compactMap { palette in palette.meanDistance(from: imageColors).map { (palette, $0) } }
            .min { $0.1 < $1.1 }
        guard let closest, closest.1 <= closestMatchMaxDistance else { return nil }
        return PaletteMatch(paletteName: closest.0.name, kind: .closest)
    }

    /// The sprite's distinct opaque colors, or `nil` past `limit`. Translucent pixels are left out:
    /// palettes are opaque, and a blended edge pixel isn't a color the artist picked.
    private static func distinctOpaqueColors(in image: UIImage, limit: Int) -> Set<ColorComponents>? {
        guard let context = CGContext.spriteDrawingContext(from: image) else { return nil }
        let pixels = ContextDataManager(context: context)
        var colors = Set<ColorComponents>()
        for y in 0..<context.height {
            for x in 0..<context.width {
                let color = pixels[PixelPoint(x: x, y: y)]
                guard color.opacity == 255 else { continue }
                colors.insert(color)
                if colors.count > limit { return nil }
            }
        }
        return colors
    }
}
