//
//  AppDelegate.swift
//  Pixel Canvas
//
//  Created by Jayden Irwin on 2018-09-29.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit
import SpritePencilKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let spritePencilAppGroupID =  "group.com.jaydenirwin.spritepencil"
    static let whatsNewCurrentVersion = 7

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.register()
        loadAppPalettes()
        
        let appGroupDefaults = UserDefaults(suiteName: AppDelegate.spritePencilAppGroupID)
        appGroupDefaults?.set(true, forKey: "ownsSpritePencil")
        
//        if UserDefaults.standard.integer(forKey: UserDefaults.Key.whatsNewVersion) == 0 {
            // Create a file manually to get iCloud Drive to show up
            if let iCloudDriveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
                do {
                    try FileManager.default.createDirectory(at: iCloudDriveURL, withIntermediateDirectories: true)
                    let testFileURL = iCloudDriveURL.appendingPathComponent("Developer Empty File").appendingPathExtension("txt")
                    try "This file is used to create your iCloud Drive folder.".write(to: testFileURL, atomically: false, encoding: .utf8)
                    try FileManager.default.removeItem(at: testFileURL)
                } catch {
                    print("unable to create icloud drive folder")
                }
            } else {
                print("unable to get icloud url")
            }
//        }
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Not sure if this is needed when using SceneDelegate
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication,
            configurationForConnecting connectingSceneSession: UISceneSession,
            options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication,
            didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        builder.remove(menu: .format)
        builder.remove(menu: .standardEdit)
        builder.remove(menu: .spelling)
        builder.remove(menu: .substitutions)
        builder.remove(menu: .transformations)
        builder.remove(menu: .speech)
        builder.remove(menu: .help)
    }
    
    func loadAppPalettes() {
        
        struct PaletteConfig {
            let name: String
            let defaultGroupLength: Int
        }
        
        do {
            let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Palettes", isDirectory: true)
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
            for fileURL in fileURLs {
                let name = fileURL.deletingPathExtension().lastPathComponent
                if let image = UIImage(contentsOfFile: fileURL.path), let palette = Palette(name: name, image: image, defaultGroupLength: 1) {
                    Palette.userPalettes.append(palette)
                } else {
                    print("Failed to load user palette")
                }
            }
        } catch {
            print("Did not find user palettes directory")
        }
        
        var configs = [
            PaletteConfig(name: "Island Joy 16", defaultGroupLength: 1),
            PaletteConfig(name: "PICO-8", defaultGroupLength: 1),
            PaletteConfig(name: "Zughy 32", defaultGroupLength: 5),
            PaletteConfig(name: "Endesga 32", defaultGroupLength: 4),
            PaletteConfig(name: "BLK 36", defaultGroupLength: 6),
            PaletteConfig(name: "Apollo", defaultGroupLength: 6),
            PaletteConfig(name: "Endesga 64", defaultGroupLength: 6),
            PaletteConfig(name: "SPF-80", defaultGroupLength: 1)
        ]
        let month = Calendar.current.component(.month, from: Date())
        let day = Calendar.current.component(.day, from: Date())
        switch month {
        case 2:
            if day == 14 {
                configs.insert(PaletteConfig(name: "Hearts", defaultGroupLength: 2), at: 0)
            }
        case 5:
            if day == 4 {
                configs.insert(PaletteConfig(name: "TIE Fighter", defaultGroupLength: 1), at: 0)
            }
        case 6:
            configs.insert(PaletteConfig(name: "Pride", defaultGroupLength: 1), at: 0)
        case 10:
            configs.insert(PaletteConfig(name: "HallowPumpkin", defaultGroupLength: 1), at: 0)
        case 12:
            configs.insert(PaletteConfig(name: "POLA5", defaultGroupLength: 1), at: 0)
        default:
            break
        }
        
        for config in configs {
            if let image = UIImage(named: config.name), let palette = Palette(name: config.name, image: image, defaultGroupLength: config.defaultGroupLength) {
                Palette.handpickedPalettes.append(palette)
                if config.name == "Endesga 32" {
                    Palette.defaultPalette = palette
                }
            }
        }
        
        let buildingBricks = Palette(name: "Building Bricks", specialCase: nil, colors: {
            let rgb: [(r: UInt8, g: UInt8, b: UInt8)] = [
                (242,243,242),(230,227,224),(160,165,169),(99,95,97),(5,19,29),(242,205,55),(201,26,9),(114,14,15),
                (180,210,227),(90,147,219),(0,85,191),(10,52,99),(75,159,74),(35,120,65),(24,70,50),(88,42,18),
                (53,33,0),(7,139,201),(169,85,0),(149,138,115),(125,191,221),(250,156,28),(208,145,104),(224,255,176),
                (187,233,11),(246,215,179),(194,218,184),(249,186,97),(254,186,189),(201,202,226),(146,57,120),(204,112,42),
                (115,220,161),(63,54,145),(199,210,60),(255,167,11),(254,138,24),(242,112,94),(96,116,161),(160,188,172),
                (132,94,132),(228,205,158),(0,143,155),(67,84,163)
            ]
            return rgb.map({ ColorComponents(red: $0.r, green: $0.g, blue: $0.b, opacity: 255) })
        }(), defaultGroupLength: 1)
        Palette.handpickedPalettes.insert(buildingBricks, at: 5)
    }

}

