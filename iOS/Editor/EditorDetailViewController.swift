//
//  EditorDetailViewController.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-01-20.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import UIKit
import SwiftUI
import SpritePencilKit

class EditorDetailViewController: SplitChildViewController {
    
    var choosePaletteBarButton: UIBarButtonItem!
    weak var documentController: DocumentController!
    weak var paletteDelegate: PaletteDelegate!
    
    lazy var paletteCollectionVC = PaletteCollectionViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        choosePaletteBarButton = UIBarButtonItem(image: UIImage(systemName: "paintpalette"), style: .plain, target: self, action: #selector(choosePaletteTapped))
        navigationItem.rightBarButtonItem = choosePaletteBarButton
        #if targetEnvironment(macCatalyst)
        navigationController?.navigationBar.isHidden = true
        #endif
        
        add(child: paletteCollectionVC)
    }
    
    #if !targetEnvironment(macCatalyst)
    override func setupForSplit(_ axis: NSLayoutConstraint.Axis) {
        navigationController?.navigationBar.isHidden = axis == .vertical
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        navigationController?.navigationBar.isHidden = view.bounds.height < view.bounds.width && view.bounds.width != 280
    }
    #endif
    
    func toolSelected(tool: Tool) {
        paletteCollectionVC.showClearColor = (tool is FillTool)
        paletteCollectionVC.collectionView.reloadData()
    }
    
    private func add(child viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
    
    @objc func choosePaletteTapped(_ sender: UIBarButtonItem) {
        doChoosePalette(button: sender)
    }
    func doChoosePalette(button: UIBarButtonItem?) {
        let paletteVC = UIHostingController(rootView: PalettePickerView(editorDetailVC: self))
        if let sender = button {
            paletteVC.modalPresentationStyle = .popover
            paletteVC.popoverPresentationController?.barButtonItem = sender
        }
        present(paletteVC, animated: true, completion: nil)
    }
    
}
