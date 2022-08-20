//
//  DocumentBrowserViewController.swift
//  Pixel Canvas
//
//  Created by Jayden Irwin on 2018-09-29.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit
import SwiftUI
import SpritePencilKit
import WelcomeKit

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    var transitionController: UIDocumentBrowserTransitionController?
    var importHandler: ((URL?, UIDocumentBrowserViewController.ImportMode) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(templatePickerDone), name: TemplatePickerView.doneNotificationName, object: nil)
        
        let whatsNewUserVersion = UserDefaults.standard.integer(forKey: UserDefaults.Key.whatsNewVersion)
        if whatsNewUserVersion < AppDelegate.whatsNewCurrentVersion {
            let features = [
                WelcomeFeature(image: Image("Apple Pencil"), title: NSLocalizedString("Apple Pencil Support", comment: ""), body: NSLocalizedString("Use your Apple Pencil to draw.", comment: "")),
                WelcomeFeature(image: Image("Sphere"), title: NSLocalizedString("Shading Tools", comment: ""), body: NSLocalizedString("Draw highlights and shadows.", comment: "")),
                WelcomeFeature(image: Image("Sprite Catalog"), title: NSLocalizedString("Sprite Catalog", comment: ""), body: NSLocalizedString("Try our new pixel asset application.", comment: ""))
            ]
            let whatsNewVC = UIHostingController(rootView: WelcomeView(isFirstLaunch: (whatsNewUserVersion == 0), appName: "Sprite Pencil", features: features))
            whatsNewVC.isModalInPresentation = true
            
            NotificationCenter.default.addObserver(forName: WelcomeView.continueNotification, object: nil, queue: nil) { (_) in
                UserDefaults.standard.set(AppDelegate.whatsNewCurrentVersion, forKey: UserDefaults.Key.whatsNewVersion)
                #if targetEnvironment(macCatalyst)
                let animated = false
                #else
                let animated = true
                #endif
                whatsNewVC.dismiss(animated: animated, completion: nil)
            }
            
            whatsNewVC.modalPresentationStyle = .formSheet
            #if targetEnvironment(macCatalyst)
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
                self.present(whatsNewVC, animated: false, completion: {
                    whatsNewVC.view.window?.windowScene?.titlebar?.titleVisibility = .hidden
                    whatsNewVC.view.window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 800, height: 620)
                    whatsNewVC.view.window?.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: 800, height: 620)
                })
            }
            #else
            present(whatsNewVC, animated: true, completion: nil)
            #endif
        }

        delegate = self
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        localizedCreateDocumentActionTitle = NSLocalizedString("Create Sprite", comment: "")
        defaultDocumentAspectRatio = 1.0
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        // Set the URL for the new document here. Optionally, you can present a template chooser before calling the importHandler.
        // Make sure the importHandler is always called, even if the user cancels the creation request.
        self.importHandler = importHandler
        
        let templatePickerVC = UIHostingController(rootView: TemplatePickerView())
        templatePickerVC.modalPresentationStyle = .formSheet
        #if targetEnvironment(macCatalyst)
        let animated = false
        #else
        let animated = true
        #endif
        present(templatePickerVC, animated: animated, completion: {
            self.view.window?.windowScene?.title = NSLocalizedString("New Sprite", comment: "")
            #if targetEnvironment(macCatalyst)
            if let titlebar = self.view.window?.windowScene?.titlebar {
                titlebar.titleVisibility = .visible
                titlebar.toolbar = nil
            }
            self.view.window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 450, height: 450)
            self.view.window?.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: 600, height: 550)
            #endif
        })
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        presentDocument(at: sourceURL, isNew: false)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL, isNew: true)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        let alert = UIAlertController(title: NSLocalizedString("Import Failed", comment: ""), message: NSLocalizedString("Failed to import your sprite.", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func templatePickerDone(notification: Notification) {
        #if targetEnvironment(macCatalyst)
        let animated = false
        #else
        let animated = true
        #endif
        presentedViewController?.dismiss(animated: animated, completion: {
            if let selectedSize = notification.object as? SpriteSize {
                var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                url.appendPathComponent(NSLocalizedString("Sprite", comment: "Default image name"))
                url.appendPathExtension("png")
                let document = Document(fileURL: url)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: selectedSize.width, height: selectedSize.height), format: format)
                document.fileData = renderer.pngData(actions: { (_) in })
                document.save(to: url, for: .forCreating) { (saveSuccess) in
                    guard saveSuccess else {
                        print("Unable to save new document.")
                        self.importHandler(nil, .none)
                        return
                    }
                    document.close(completionHandler: { (closeSuccess) in
                        guard closeSuccess else {
                            print("Unable to close new document.")
                            self.importHandler(nil, .none)
                            return
                        }
                        self.importHandler(url, .move)
                        
                        let createdDocumentsCount = UserDefaults.standard.integer(forKey: UserDefaults.Key.createdDocumentsCount)
                        UserDefaults.standard.set(createdDocumentsCount+1, forKey: UserDefaults.Key.createdDocumentsCount)
                        UserDefaults.standard.set(String(createdDocumentsCount+1), forKey: UserDefaults.Key.createdDocumentsCountText)
                    })
                }
            } else {
                self.importHandler(nil, .none)
            }
        })
    }
    
    func presentDocument(at documentURL: URL, isNew: Bool) {
        let documentViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DocumentViewController") as! EditorViewController
        documentViewController.document = Document(fileURL: documentURL)
        documentViewController.documentWasNewlyCreated = isNew
        let documentNavVC = UINavigationController(rootViewController: documentViewController)
        
        let detailVC = EditorDetailViewController()
        let detailNavVC = UINavigationController(rootViewController: detailVC)
        documentViewController.detailVC = detailVC
        
        let splitViewController = AutoSplitViewController()
        splitViewController.leadingViewController = documentNavVC
        splitViewController.trailingViewController = detailNavVC
        splitViewController.modalPresentationStyle = .fullScreen
        
        documentViewController.paletteCollectionVC = detailVC.paletteCollectionVC
        let palette: Palette = {
            if let palette = documentViewController.canvasView?.documentController?.palette {
                return palette
            } else if let nameString = UserDefaults.standard.string(forKey: UserDefaults.Key.colorPalette) {
                return Palette.allPalettes.first(where: { $0.name == nameString }) ?? Palette.defaultPalette
            } else {
                return Palette.defaultPalette
            }
        }()
        detailVC.paletteCollectionVC.loadPalette(palette)
        detailVC.paletteCollectionVC.collectionView.selectItem(at: IndexPath(item: 0, section: 1), animated: false, scrollPosition: .centeredVertically)
        
        #if targetEnvironment(macCatalyst)
        if isNew {
            present(splitViewController, animated: false, completion: nil)
        } else {
            view.window?.rootViewController = splitViewController // Big Sur 11.2 Bug workaround
        }
        #else
        transitionController = transitionController(forDocumentAt: documentURL)
        transitionController?.targetView = documentViewController.canvasView
        splitViewController.transitioningDelegate = self
        
        present(splitViewController, animated: true, completion: nil)
        #endif
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionController
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionController
    }
    
}

