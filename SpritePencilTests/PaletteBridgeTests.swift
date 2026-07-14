import Testing
import Foundation
import PaletteKit
import SpritePencilKit
@testable import Sprite_Pencil

/// The handpicked palettes now come from PaletteKit rather than bundled images, so what needs
/// locking down is that the bridge lands on the *same* palettes the app has always shipped —
/// same list, same order, same grouping, same exact bytes.
struct PaletteBridgeTests {

    private func handpicked(month: Int, day: Int = 1) throws -> [SpritePencilKit.Palette] {
        let date = try #require(DateComponents(calendar: .current, year: 2026, month: month, day: day).date)
        return SpritePencilKit.Palette.handpicked(on: date)
    }

    @Test func handpickedListMatchesTheShippedOrder() throws {
        #expect(try handpicked(month: 7).map(\.name) == [
            "Island Joy 16", "PICO-8", "Zughy 32", "Endesga 32", "BLK 36",
            "Building Bricks", "Apollo", "Endesga 64", "SPF-80",
        ])
    }

    /// A seasonal palette leads the list. Building Bricks holds slot 5 either way, so in season it
    /// lands ahead of BLK 36 rather than behind it — odd, but exactly what the app has always done.
    @Test(arguments: [(2, 14, "Hearts"), (5, 4, "TIE Fighter"), (6, 1, "Pride"), (10, 1, "HallowPumpkin"), (12, 1, "POLA5")])
    func seasonalPaletteLeadsItsSeason(month: Int, day: Int, name: String) throws {
        let names = try handpicked(month: month, day: day).map(\.name)
        #expect(names.first == name)
        #expect(names.firstIndex(of: "Building Bricks") == 5)
    }

    @Test func endesga32IsTheDefault() throws {
        let palettes = try handpicked(month: 7)
        let `default` = try #require(palettes.first { $0.name == SpritePencilKit.Palette.defaultPremadeName })
        #expect(`default`.name == "Endesga 32")
        #expect(`default`.colors.count == 32)
    }

    /// The swatch grid lays out in these chunks — a lost group length re-flows every palette.
    @Test func groupLengthsSurviveTheBridge() throws {
        let lengths = try Dictionary(uniqueKeysWithValues: handpicked(month: 7).map { ($0.name, $0.defaultGroupLength) })
        #expect(lengths["Zughy 32"] == 5)
        #expect(lengths["Endesga 32"] == 4)
        #expect(lengths["BLK 36"] == 6)
        #expect(lengths["Apollo"] == 6)
        #expect(lengths["PICO-8"] == 1)
    }

    /// PaletteKit stores colors as perceptual fractions, so the bridge realizes them back to bytes.
    /// Anything less than exact would shift every premade color the editor paints with.
    @Test(arguments: ["#000000", "#FFFFFF", "#FF004D", "#1A2B3C", "#7E2553"])
    func colorsBridgeBackToTheExactSRGBBytes(hex: String) throws {
        let bridged = ColorComponents(try #require(PaletteColor(hex: hex, colorSpace: .okLch)))
        #expect(bridged == ColorComponents(hex: hex))
        #expect(bridged.opacity == 255)
    }
}
