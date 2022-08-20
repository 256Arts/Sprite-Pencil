//
//  UserDefaults.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-01-20.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import Foundation
import SpritePencilKit

extension UserDefaults {
    
    struct Key {
        static let whatsNewVersion = "whatsNewVersion"
        static let showPermanentEditWarning = "showPermanentEditWarning"
        static let createdDocumentsCount = "createdDocumentsCount"
        static let createdDocumentsCountText = "createdDocumentsCountText"
        static let documentsClosedCount = "documentsClosedCount"
        static let colorPalette = "colorPalette"
        static let showPalette = "showPalette"
        static let currentColor = "currentColor"
        static let premium = "premium"
        
        static let fingerAction = "fingerAction"
        static let twoFingerUndoEnabled = "twoFingerUndoEnabled"
        static let showColorNotifications = "showColorNotifications"
        static let autosave = "autosave"
    }
    
    func register() {
        register(defaults: [
            Key.whatsNewVersion: 0,
            Key.showPermanentEditWarning: true,
            Key.createdDocumentsCount: 0,
            Key.createdDocumentsCountText: "0",
            Key.documentsClosedCount: 0,
            Key.showPalette: true,
            Key.colorPalette: Palette.defaultPalette.name,
            Key.premium: false,
            
            Key.fingerAction: "ignore",
            Key.twoFingerUndoEnabled: true,
            Key.showColorNotifications: false,
            Key.autosave: true
        ])
    }
    
}
