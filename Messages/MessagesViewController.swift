//
//  MessagesViewController.swift
//  messages
//
//  Created by Jayden Irwin on 2018-10-15.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit
import Messages
import SpritePencilKit

class MessagesViewController: MSMessagesAppViewController, PaletteDelegate {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var canvasView: CanvasView!
    
    var paletteCollectionVC: PaletteCollectionViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIGraphicsBeginImageContext(CGSize(width: 16, height: 16))
        canvasView.zoomEnabled = false
        canvasView.documentController = DocumentController(canvasView: canvasView)
        canvasView.documentController.palette = Palette.sp16
        canvasView.documentController.context = UIGraphicsGetCurrentContext()
        canvasView.setupView()
        canvasView.layer.magnificationFilter = .nearest
        
        paletteCollectionVC = PaletteCollectionViewController()
        paletteCollectionVC.messagesAppMode = true
        paletteCollectionVC.view.tintColor = view.tintColor
        paletteCollectionVC.paletteDelegate = self
        paletteCollectionVC.loadPalette(Palette.sp16)
        let controlsStackView = stackView.arrangedSubviews[1] as! UIStackView
        controlsStackView.addArrangedSubview(paletteCollectionVC.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // iOS bug workaround
            self.canvasView.zoomToFit()
            self.paletteCollectionVC.refreshCellSize(size: self.paletteCollectionVC.view.bounds.size)
        }
    }
    
    func selectedColorDidChange(colorComponents components: ColorComponents) {
        canvasView.documentController.toolColorComponents = components
        if !(canvasView.tool is FillTool) {
            canvasView.tool = canvasView.documentController.pencilTool
        }
    }
    
    @IBAction func clearTapped(_ sender: Any) {
        canvasView.documentController.context.clear()
        canvasView.documentController.refresh()
    }
    
    @IBAction func insertTapped() {
        guard let image = canvasView.documentController.export(scale: 10), let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let filePath = path.appendingPathComponent("TempSticker.png")
        do {
            try image.pngData()?.write(to: filePath)
            let sticker = try MSSticker(contentsOfFileURL: filePath, localizedDescription: "Custom Sprite")
            activeConversation?.insert(sticker) { (error) in
                if let error = error {
                    print(error)
                } else {
                    self.requestPresentationStyle(.compact)
                }
            }
        } catch {
            print(error)
        }
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        stackView.axis = (view.bounds.height < 500) ? .horizontal : .vertical
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // iOS bug workaround
            self.canvasView.zoomToFit()
            self.paletteCollectionVC.refreshCellSize(size: self.paletteCollectionVC.view.bounds.size)
        }
    }

}
