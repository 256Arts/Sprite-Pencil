//
//  SceneDelegate.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-09-05.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import UIKit
import SwiftUI
import SpritePencilKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    struct LospecPalette: Codable {
        let name: String
        let author: String
        let colors: [String]
    }
    
    var window: UIWindow?
    var addPaletteVC: UIViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.windowScene = windowScene
        let rootVC = DocumentBrowserViewController()
        window?.rootViewController = rootVC
        window?.tintColor = UIColor(named: "Brand")
        window?.makeKeyAndVisible()
        
        if let userActivity = connectionOptions.userActivities.first,
              userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL {
            importSpriteFromAppGroup(userActivityURL: incomingURL)
        } else if let url = connectionOptions.urlContexts.first?.url {
            handleCustomURL(url: url)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for urlContext in URLContexts {
            // Ensure the URL is a file URL
            if urlContext.url.isFileURL {
                // Reveal / import the document at the URL
                guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return }

//                documentBrowserViewController.revealDocument(at: urlContext.url, importIfNeeded: true) { (revealedDocumentURL, error) in
//                    if let error = error {
//                        // Handle the error appropriately
//                        print("Failed to reveal the document at URL \(urlContext.url) with error: '\(error)'")
//                        return
//                    }
//
                    // Present the Document View Controller for the revealed URL
                    documentBrowserViewController.presentDocument(at: urlContext.url, isNew: false)
//                }
            } else {
                handleCustomURL(url: urlContext.url)
            }
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        #if !targetEnvironment(macCatalyst)
        if let url = userActivity.userInfo?[UIDocument.userActivityURLKey] as? URL {
            guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return }
            documentBrowserViewController.presentDocument(at: url, isNew: false)
        } else if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                  let incomingURL = userActivity.webpageURL {
            importSpriteFromAppGroup(userActivityURL: incomingURL)
        }
        #endif
//        documentBrowserViewController.revealDocument(at: url, importIfNeeded: true) { (revealedDocumentURL, error) in
//            if let error = error {
//                // Handle the error appropriately
//                print("Failed to reveal the document at URL \(url) with error: '\(error)'")
//                return
//            }
//
//            // Present the Document View Controller for the revealed URL
//            documentBrowserViewController.presentDocument(at: revealedDocumentURL!, isNew: false)
//        }
    }
    
    func handleCustomURL(url: URL) {
        if url.scheme == "spritepencil" && url.host == "importfromapp" {
            importSpriteFromAppGroup(userActivityURL: nil)
        } else {
            openLospecURL(url)
        }
    }
    
    func importSpriteFromAppGroup(userActivityURL: URL?) {
        guard userActivityURL == nil || userActivityURL?.path == "/spritepencil/importfromapp" else {
            print("unknown user activity URL")
            return
        }
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return }
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppDelegate.spritePencilAppGroupID) else { return }
        let importSpriteImageURL = containerURL.appendingPathComponent("Import").appendingPathExtension("png")
        guard let imageData = try? Data(contentsOf: importSpriteImageURL) else { return }
        
        let appGroupDefaults = UserDefaults(suiteName: AppDelegate.spritePencilAppGroupID)
        let preferedFileName = appGroupDefaults?.string(forKey: "importSpriteName")
        
        var url = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        url.appendPathComponent(preferedFileName ?? NSLocalizedString("Sprite", comment: "Default image name"))
        url.appendPathExtension("png")
        let document = Document(fileURL: url)
        document.fileData = imageData
        document.save(to: url, for: .forCreating) { (saveSuccess) in
            guard saveSuccess else {
                print("Unable to save new document.")
                return
            }
            document.close(completionHandler: { (closeSuccess) in
                guard closeSuccess else {
                    print("Unable to close new document.")
                    return
                }
                documentBrowserViewController.presentDocument(at: url, isNew: true)
                
                let createdDocumentsCount = UserDefaults.standard.integer(forKey: UserDefaults.Key.createdDocumentsCount)
                UserDefaults.standard.set(createdDocumentsCount+1, forKey: UserDefaults.Key.createdDocumentsCount)
                UserDefaults.standard.set(String(createdDocumentsCount+1), forKey: UserDefaults.Key.createdDocumentsCountText)
            })
        }
    }
    
    func openLospecURL(_ url: URL) {
        guard url.scheme == "lospec-palette", let paletteSlug = url.host else { return }
        guard let jsonURL = URL(string: "https://lospec.com/palette-list/\(paletteSlug).json") else { return }
        let task = URLSession.shared.dataTask(with: jsonURL) { (data, response, error) in
            print(error)
            guard let data = data else { return }
            do {
                let lospecPalette = try JSONDecoder().decode(LospecPalette.self, from: data)
                let colorComps = lospecPalette.colors.map({ ColorComponents(hex: $0) })
                guard let colors = colorComps as? [ColorComponents] else { return }
                let palette = Palette(name: lospecPalette.name, specialCase: nil, colors: colors, defaultGroupLength: 1)
                
                let addVC = UIHostingController(rootView: AddPaletteView(palette: palette, fromLospec: true))
                addVC.modalPresentationStyle = .formSheet
                DispatchQueue.main.async {
                    var topViewController: UIViewController = self.window!.rootViewController!
                    while (topViewController.presentedViewController) != nil {
                        topViewController = topViewController.presentedViewController!
                    }
                    topViewController.present(addVC, animated: true, completion: nil)
                    
                    self.addPaletteVC = addVC
                    NotificationCenter.default.addObserver(self, selector: #selector(self.dismissAddPalette), name: AddPaletteView.dismissNotificationName, object: nil)
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    @objc func dismissAddPalette(notification: Notification) {
        addPaletteVC?.dismiss(animated: true, completion: nil)
        addPaletteVC = nil
    }
    
}
