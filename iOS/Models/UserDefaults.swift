//
//  UserDefaults.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2019-01-20.
//  Copyright © 2019 256 Arts Developer. All rights reserved.
//

import Foundation
import SpritePencilKit

extension UserDefaults {
    
    struct Key {
        static let showPermanentEditWarning = "showPermanentEditWarning"
        static let createdDocumentsCount = "createdDocumentsCount"
        static let createdDocumentsCountText = "createdDocumentsCountText"
        static let documentsClosedCount = "documentsClosedCount"
        static let colorPalette = "colorPalette"
        static let showPalette = "showPalette"
        static let showPixelGrid = "showPixelGrid"
        static let showTileGrid = "showTileGrid"
        static let currentColor = "currentColor"
        
        static let canvasBackgroundColor = "canvasBackgroundColor"
        static let fingerAction = "fingerAction"
        static let twoFingerUndoEnabled = "twoFingerUndoEnabled"
        static let showColorNotifications = "showColorNotifications"
        
    }
    
    func register() {
        register(defaults: [
            Key.showPermanentEditWarning: true,
            Key.createdDocumentsCount: 0,
            Key.createdDocumentsCountText: "0",
            Key.documentsClosedCount: 0,
            Key.showPalette: true,
            Key.showPixelGrid: false,
            Key.showTileGrid: false,
            Key.colorPalette: Palette.defaultPalette.name,
            
            Key.canvasBackgroundColor: "default",
            Key.fingerAction: "ignore",
            Key.twoFingerUndoEnabled: true,
            Key.showColorNotifications: false,
        ])
    }
    
    func incrementDocumentsCreatedCount() {
        let createdDocumentsCount = integer(forKey: UserDefaults.Key.createdDocumentsCount) + 1
        set(createdDocumentsCount, forKey: UserDefaults.Key.createdDocumentsCount)
        set(String(createdDocumentsCount), forKey: UserDefaults.Key.createdDocumentsCountText)
    }
    
}
