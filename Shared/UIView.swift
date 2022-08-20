//
//  UIView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2018-10-02.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
}
