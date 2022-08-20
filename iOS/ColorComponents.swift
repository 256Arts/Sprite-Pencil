//
//  ColorComponents.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-09-14.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SpritePencilKit

extension ColorComponents {
    
    var hex: String {
        String(format: "#%02lX%02lX%02lX", red, green, blue)
    }
    
}
