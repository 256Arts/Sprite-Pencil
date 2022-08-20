//
//  SpriteSize.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2021-04-15.
//  Copyright © 2021 Jayden Irwin. All rights reserved.
//

import Foundation

struct SpriteSize: Identifiable, Equatable {
    
    static let defaultSize = SpriteSize(width: 16, height: 16)
    static var maxSize = SpriteSize(width: 1024, height: 1024)
    static let squareSizes = [SpriteSize(width: 8, height: 8), SpriteSize(width: 16, height: 16), SpriteSize(width: 24, height: 24), SpriteSize(width: 32, height: 32), SpriteSize(width: 64, height: 64)]
    static let widescreenSizes = [SpriteSize(width: 128, height: 72), SpriteSize(width: 256, height: 144), SpriteSize(width: 512, height: 288)]
    
    var width: Int
    var height: Int
    var id: String {
        "\(width)x\(height)"
    }
}
