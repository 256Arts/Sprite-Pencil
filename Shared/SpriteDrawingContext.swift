//
//  SpriteDrawingContext.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2026-06-25.
//  Copyright © 2026 Jayden Irwin. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public extension CGContext {

    /// Creates an empty pixel-art drawing context for the engine to draw into.
    ///
    /// `SpritePencilKit` reads and writes pixels directly through
    /// `getColorComponents(at:)` / `simplePaint(...)`, which assume a BGRA,
    /// premultiplied-first, little-endian, **sRGB** buffer. Building the context
    /// here — instead of via `UIGraphicsBeginImageContext`, which is *device RGB*
    /// — keeps painted colors, the eyedropper, and the saved PNG all in one color
    /// space, so colors round-trip exactly (fixes the eyedropper reading slightly
    /// wrong colors).
    static func spriteDrawingContext(width: Int, height: Int) -> CGContext? {
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: bitmapInfo)
    }

    /// Creates a pixel-art drawing context seeded with `image`, normalizing it to
    /// the engine's sRGB buffer so eyedropped colors match the palette.
    static func spriteDrawingContext(from image: UIImage) -> CGContext? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard let context = spriteDrawingContext(width: width, height: height) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context
    }

}
#endif
