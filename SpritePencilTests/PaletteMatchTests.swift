import Testing
import UIKit
import SpritePencilKit
@testable import Sprite_Pencil

struct PaletteMatchTests {

    private func color(_ hex: String) -> ColorComponents { ColorComponents(hex: hex)! }

    private func palette(_ name: String, _ hexes: [String]) -> Palette {
        Palette(name: name, specialCase: nil, colors: hexes.map(color), defaultGroupLength: 1)
    }

    /// A 1px-tall sprite with one pixel per color.
    private func sprite(_ hexes: [String]) throws -> UIImage {
        try UIImage(data: #require(palette("Sprite", hexes).pngData()))!
    }

    private let small = ["000000", "ffffff", "ff0000"]

    @Test func picksSmallestPaletteContainingEveryColor() throws {
        let big = palette("Big", small + ["00ff00", "0000ff"])
        let tight = palette("Tight", small + ["00ff00"])
        let match = PaletteMatch.find(for: try sprite(small), among: [big, tight], preferring: nil)
        #expect(match == PaletteMatch(paletteName: "Tight", kind: .exact))
    }

    @Test func prefersTheCurrentPaletteWhenItFits() throws {
        let big = palette("Big", small + ["00ff00", "0000ff"])
        let tight = palette("Tight", small)
        let match = PaletteMatch.find(for: try sprite(small), among: [big, tight], preferring: big)
        #expect(match?.paletteName == "Big")
    }

    @Test func labelsANearMissAsClosest() throws {
        let near = palette("Near", ["000000", "fefefe", "fe0000"])
        let far = palette("Far", ["00ff00", "0000ff", "ffff00"])
        let match = PaletteMatch.find(for: try sprite(small), among: [far, near], preferring: nil)
        #expect(match == PaletteMatch(paletteName: "Near", kind: .closest))
    }

    @Test func ignoresPalettesThatAreNotClose() throws {
        let far = palette("Far", ["00ff00", "0000ff", "ffff00"])
        #expect(PaletteMatch.find(for: try sprite(small), among: [far], preferring: nil) == nil)
    }

    @Test func skipsGeneratedPalettesAndTooFewColors() throws {
        #expect(PaletteMatch.find(for: try sprite(small), among: [.rrggbb], preferring: nil) == nil)
        #expect(PaletteMatch.find(for: try sprite(["000000", "ffffff"]), among: [palette("BW", ["000000", "ffffff"])], preferring: nil) == nil)
    }
}
