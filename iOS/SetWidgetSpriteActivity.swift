//
//  SetWidgetSpriteActivity.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-10-02.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import UIKit
import WidgetKit
import SpritePencilKit

class SetWidgetSpriteActivity: UIActivity {
    
    override var activityType: UIActivity.ActivityType? {
        .init("setWidgetSprite")
    }
    override var activityTitle: String? {
        NSLocalizedString("Set Widget Sprite", comment: "")
    }
    override var activityImage: UIImage? {
        UIImage(systemName: "square", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
    }
    
    var image: UIImage?
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if item is UIImage {
                return true
            }
        }
        return false
    }
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let image = item as? UIImage {
                self.image = image
            }
        }
    }
    override func perform() {
        if let defaults = UserDefaults(suiteName: "group.com.jaydenirwin.spritepencil"), let data = image?.pngData() {
            defaults.set(data, forKey: "sprite")
            if let hex = UserDefaults.standard.string(forKey: UserDefaults.Key.currentColor) {
                defaults.set(hex, forKey: "backgroundColor")
            }
            WidgetCenter.shared.reloadAllTimelines()
            let request = AppNotificationRequest(title: NSLocalizedString("Widget Updated", comment: ""), color: nil)
            for window in UIApplication.shared.windows {
                window.showAppNotification(request)
            }
        }
    }
    
}
