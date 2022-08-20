//
//  Palette.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-05-19.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import UIKit
import SpritePencilKit

extension Palette {
    
    public static var defaultPalette = Palette.sp16
    public static var userPalettes = [Palette]()
    public static var handpickedPalettes = [Palette]()
    public static var allPalettes: [Palette] {
        return userPalettes + handpickedPalettes + [Palette.sp16, Palette.rrggbb, Palette.hhhhssbb, Palette.rrrgggbb]
    }
    
    static func addPalette(_ palette: Palette, paletteImage: UIImage?) {
        Palette.userPalettes.append(palette)
        
        let image = paletteImage ?? {
            UIGraphicsBeginImageContext(CGSize(width: palette.colors.count, height: 1))
            guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
            let contextDataManager = ContextDataManager(context: context)
            let cdp = contextDataManager.dataPointer
            
            for (x, colorComponents) in palette.colors.enumerated() {
                let point = PixelPoint(x: x, y: 0)
                let offset = contextDataManager.dataOffset(for: point)
                cdp[offset+2] = colorComponents.red
                cdp[offset+1] = colorComponents.green
                cdp[offset] = colorComponents.blue
                cdp[offset+3] = colorComponents.opacity
            }
            defer {
                UIGraphicsEndImageContext()
            }
            return UIGraphicsGetImageFromCurrentImageContext()!
        }()
        
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Palettes", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            let imageURL = directoryURL.appendingPathComponent(palette.name, isDirectory: false).appendingPathExtension("png")
            try image.pngData()?.write(to: imageURL)
        } catch {
            print("Failed to write palette file or directory")
            print(error)
        }
    }
    
}
