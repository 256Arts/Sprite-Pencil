//
//  ColorComponents.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2020-09-14.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SpritePencilKit
import SwiftUI
import UIKit

extension ColorComponents {

    var hex: String {
        String(format: "#%02lX%02lX%02lX", red, green, blue)
    }

    /// Creates sRGB color components from a SwiftUI `Color`.
    ///
    /// Each channel is clamped to `0...1` and rounded to the nearest 8-bit
    /// value. Wide-gamut colors resolve to *extended* sRGB channels that can
    /// fall outside `0...1`; without clamping the `UInt8` conversion would trap,
    /// and truncating (rather than rounding) yielded slightly-off colors that
    /// failed to round-trip. This is the inverse of `Color(components:)`.
    init(_ color: Color) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        func channel(_ value: CGFloat) -> UInt8 {
            UInt8((min(max(value, 0), 1) * 255).rounded())
        }
        self.init(.sRGB, red: channel(red), green: channel(green), blue: channel(blue), opacity: channel(alpha))
    }

}
