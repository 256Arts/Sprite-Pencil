//
//  PaletteColorCell.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2018-10-02.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit

class PaletteColorCell: UICollectionViewCell {
    
    let colorView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        #if targetEnvironment(macCatalyst)
        cornerRadius = 7.0
        colorView.cornerRadius = 3.0
        #else
        cornerRadius = 9.0
        colorView.cornerRadius = 5.0
        #endif
        colorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(colorView)
        addConstraints([
            colorView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            colorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            colorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            colorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
