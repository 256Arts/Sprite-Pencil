//
//  CreatePaletteActivity.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-05-19.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import UIKit
import SwiftUI
import SpritePencilKit

class SaveAsPaletteActivity: UIActivity {
    
    override var activityType: UIActivity.ActivityType? {
        .init("saveAsPalette")
    }
    override var activityTitle: String? {
        NSLocalizedString("Save as Palette", comment: "")
    }
    override var activityImage: UIImage? {
        UIImage(systemName: "paintpalette", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
    }
    override var activityViewController: UIViewController? {
        guard let palette = palette else { return nil }
        let addVC = UIHostingController(rootView: AddPaletteView(palette: palette, fromLospec: false, paletteImage: image, completionHandler: { success in
            self.activityDidFinish(success)
        }))
        addVC.modalPresentationStyle = .formSheet
        
        NotificationCenter.default.addObserver(forName: AddPaletteView.dismissNotificationName, object: self, queue: .main) { (_) in
            addVC.dismiss(animated: true, completion: nil)
        }
        
        return addVC
    }
    
    var palette: Palette?
    var image: UIImage?
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let image = item as? UIImage, image.size.height == 1 {
                return true
            }
        }
        return false
    }
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let image = item as? UIImage, let palette = Palette(name: NSLocalizedString("My Palette", comment: "default palette name"), image: image, defaultGroupLength: 1) {
                self.palette = palette
                self.image = image
            }
        }
    }
    
}
