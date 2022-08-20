//
//  DocumentPresentationViewController.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2018-11-14.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit

class DocumentPresentationViewController: UIViewController {
    
    let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = imageView
        imageView.layer.magnificationFilter = .nearest
    }
    
}
