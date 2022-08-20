//
//  MacToolbarDelegate.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-11-08.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

#if targetEnvironment(macCatalyst)
import UIKit

protocol MacToolbarActionsDelegate: AnyObject {
    var documentMenu: UIMenu? { get }
    
    func spritesClicked(_ sender: UIBarButtonItem)
    func shareClicked(_ sender: UIBarButtonItem)
    func choosePaletteClicked(_ sender: UIBarButtonItem)
    func sidebarButtonClicked(_ sender: UIBarButtonItem)
    func vSymmetryClicked()
    func hSymmetryClicked()
    func pixelGridClicked()
    func tileGridClicked()
}

class MacToolbarDelegate: NSObject, NSToolbarDelegate {
    
    weak var delegate: MacToolbarActionsDelegate?
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "sprites":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(title: NSLocalizedString("Sprites", comment: ""), style: .plain, target: self, action: #selector(spritesClicked)))
            item.label = NSLocalizedString("Sprites", comment: "")
            item.isNavigational = true
            return item
        case "document":
            let item = NSMenuToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: delegate?.documentMenu))
            item.label = NSLocalizedString("Document", comment: "")
            item.itemMenu = delegate?.documentMenu ?? UIMenu()
            return item
        case "share":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareClicked)))
            item.label = NSLocalizedString("Share", comment: "")
            return item
        case "choosePalette":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(image: UIImage(systemName: "paintpalette"), style: .plain, target: self, action: #selector(choosePaletteClicked)))
            item.label = NSLocalizedString("Palette", comment: "")
            return item
        case "sidebar":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(image: UIImage(systemName: "sidebar.right"), style: .plain, target: self, action: #selector(sidebarButtonClicked)))
            item.label = NSLocalizedString("Sidebar", comment: "")
            return item
        case "vSymmetry":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(image: UIImage(systemName: "square.lefthalf.fill"), style: .plain, target: self, action: #selector(vSymmetryClicked)))
            item.label = NSLocalizedString("V Symmetry", comment: "")
            return item
        case "hSymmetry":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(image: UIImage(systemName: "square.bottomhalf.fill"), style: .plain, target: self, action: #selector(hSymmetryClicked)))
            item.label = NSLocalizedString("H Symmetry", comment: "")
            return item
        case "pixelGrid":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(image: UIImage(systemName: "squareshape.split.3x3"), style: .plain, target: self, action: #selector(hSymmetryClicked)))
            item.label = NSLocalizedString("Pixel Grid", comment: "")
            return item
        case "tileGrid":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(image: UIImage(systemName: "squareshape.split.2x2"), style: .plain, target: self, action: #selector(hSymmetryClicked)))
            item.label = NSLocalizedString("Tile Grid", comment: "")
            return item
        default:
            return nil
        }
    }
        
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
//            NSToolbarItem.Identifier("sprites"), // Not needed while using 11.2 rootviewcontroller bug workaround
            NSToolbarItem.Identifier.flexibleSpace,
            NSToolbarItem.Identifier("document"),
            NSToolbarItem.Identifier("share"),
            NSToolbarItem.Identifier("choosePalette"),
            NSToolbarItem.Identifier("sidebar")
        ]
    }
        
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            NSToolbarItem.Identifier("sprites"),
            NSToolbarItem.Identifier("document"),
            NSToolbarItem.Identifier("share"),
            NSToolbarItem.Identifier("choosePalette"),
            NSToolbarItem.Identifier("sidebar"),
            NSToolbarItem.Identifier("vSymmetry"),
            NSToolbarItem.Identifier("hSymmetry"),
            NSToolbarItem.Identifier("pixelGrid"),
            NSToolbarItem.Identifier("tileGrid")
        ]
    }
    
    @objc func spritesClicked(_ sender: UIBarButtonItem) {
        delegate?.spritesClicked(sender)
    }
    @objc func shareClicked(_ sender: UIBarButtonItem) {
        delegate?.shareClicked(sender)
    }
    @objc func choosePaletteClicked(_ sender: UIBarButtonItem) {
        delegate?.choosePaletteClicked(sender)
    }
    @objc func sidebarButtonClicked(_ sender: UIBarButtonItem) {
        delegate?.sidebarButtonClicked(sender)
    }
    @objc func vSymmetryClicked(_ sender: UIBarButtonItem) {
        delegate?.vSymmetryClicked()
    }
    @objc func hSymmetryClicked(_ sender: UIBarButtonItem) {
        delegate?.hSymmetryClicked()
    }
    @objc func pixelGridClicked(_ sender: UIBarButtonItem) {
        delegate?.pixelGridClicked()
    }
    @objc func tileGridClicked(_ sender: UIBarButtonItem) {
        delegate?.tileGridClicked()
    }
    
}
#endif
