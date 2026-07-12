//
//  SpritePencilTests.swift
//  Sprite Pencil
//
//  Pure-logic regression coverage for the app-side value types: the raw
//  values persisted in user settings (CanvasBackground, FingerAction), the
//  Lospec palette JSON shape, sprite-size identity, and the recent-colors
//  ordering rules. No canvas or view is involved — the drawing engine has its
//  own suite in SpritePencilKitTests.
//

import Testing
import Foundation
import SpritePencilKit
@testable import Sprite_Pencil

struct CanvasBackgroundTests {

    @Test func rawValuesAreStable() {
        // Persisted under UserDefaults.Key.canvasBackgroundColor — changing any
        // of these silently resets existing users' checkerboard choice.
        #expect(CanvasBackground.default.rawValue == "default")
        #expect(CanvasBackground.white.rawValue == "white")
        #expect(CanvasBackground.pink.rawValue == "pink")
        #expect(CanvasBackground.green.rawValue == "green")
    }

    @Test func rawValueRoundTrips() {
        for background in CanvasBackground.allCases {
            #expect(CanvasBackground(rawValue: background.rawValue) == background)
            #expect(background.id == background.rawValue)
        }
    }

    @Test func casesAreExhaustiveAndOrdered() {
        #expect(CanvasBackground.allCases == [.default, .white, .pink, .green])
    }
}

struct FingerActionTests {

    @Test func rawValuesAreStable() {
        // The kit owns FingerAction; the app persists its raw value under
        // UserDefaults.Key.fingerAction, so these strings must not drift.
        #expect(FingerAction.draw.rawValue == "draw")
        #expect(FingerAction.move.rawValue == "move")
        #expect(FingerAction.eyedrop.rawValue == "eyedrop")
        #expect(FingerAction.ignore.rawValue == "ignore")
    }

    @Test func userSelectableCasesOmitDraw() {
        // `.draw` is the implicit behavior, not a Settings choice.
        #expect(FingerAction.userSelectableCases == [.move, .eyedrop, .ignore])
        #expect(!FingerAction.userSelectableCases.contains(.draw))
    }
}

struct SpriteSizeTests {

    @Test func idEncodesDimensions() {
        #expect(SpriteSize(width: 16, height: 16).id == "16x16")
        #expect(SpriteSize(width: 128, height: 72).id == "128x72")
    }

    @Test func defaultAndPresetsAreStable() {
        #expect(SpriteSize.defaultSize == SpriteSize(width: 16, height: 16))
        #expect(SpriteSize.squareSizes.first == SpriteSize(width: 8, height: 8))
        #expect(SpriteSize.squareSizes.count == 5)
        #expect(SpriteSize.widescreenSizes.allSatisfy { $0.width > $0.height })
    }

    @Test func equalityIsComponentwise() {
        #expect(SpriteSize(width: 8, height: 16) != SpriteSize(width: 16, height: 8))
        #expect(SpriteSize(width: 8, height: 16) == SpriteSize(width: 8, height: 16))
    }
}

struct LospecDecodingTests {

    @Test func decodesTheLospecJSONShape() throws {
        // The exact shape returned by lospec.com/palette-list/<slug>.json.
        let json = Data("""
        {
          "name": "Sweetie 16",
          "author": "GrafxKid",
          "colors": ["1a1c2c", "5d275d", "b13e53", "ef7d57"]
        }
        """.utf8)

        let palette = try JSONDecoder().decode(AppCoordinator.LospecPalette.self, from: json)
        #expect(palette.name == "Sweetie 16")
        #expect(palette.author == "GrafxKid")
        #expect(palette.colors == ["1a1c2c", "5d275d", "b13e53", "ef7d57"])

        // The colors are hex strings the app feeds to ColorComponents(hex:).
        #expect(ColorComponents(hex: palette.colors[0]) != nil)
    }
}

@MainActor
struct RecentColorsTests {

    private func opaque(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> ColorComponents {
        ColorComponents(red: red, green: green, blue: blue, opacity: 255)
    }

    @Test func newestColorGoesToTheFront() {
        let controller = PaletteCollectionController()
        let a = opaque(10, 0, 0), b = opaque(0, 20, 0)
        controller.usedColor(components: a)
        controller.usedColor(components: b)
        #expect(controller.recentColors == [b, a])
    }

    @Test func reusingAColorPromotesItWithoutDuplicating() {
        let controller = PaletteCollectionController()
        let a = opaque(10, 0, 0), b = opaque(0, 20, 0), c = opaque(0, 0, 30)
        [a, b, c, a].forEach { controller.usedColor(components: $0) }
        #expect(controller.recentColors == [a, c, b])
    }

    @Test func listIsCappedAtTheMaximum() {
        let controller = PaletteCollectionController()
        let max = controller.maxRecentColorCount
        for i in 0...(max + 4) {
            controller.usedColor(components: opaque(UInt8(i), UInt8(i), UInt8(i)))
        }
        #expect(controller.recentColors.count == max)
        // The oldest colors fell off the end; the newest is at the front.
        #expect(controller.recentColors.first == opaque(UInt8(max + 4), UInt8(max + 4), UInt8(max + 4)))
    }

    @Test func translucentColorsAreIgnored() {
        let controller = PaletteCollectionController()
        controller.usedColor(components: ColorComponents(red: 10, green: 10, blue: 10, opacity: 128))
        #expect(controller.recentColors.isEmpty)
    }
}
