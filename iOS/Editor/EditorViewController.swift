import UIKit
import SwiftUI
import StoreKit
import SpritePencilKit

class EditorViewController: SplitChildViewController, ObservableObject, ToolDelegate, EditorDelegate, PaletteDelegate, CanvasViewDelegate, SKStoreProductViewControllerDelegate {
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var sidebarButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var canvasView: CanvasView!
    @IBOutlet weak var toolbarView: UIView!
    let toolStackBorder = CALayer()
    
    let appStoreVC = SKStoreProductViewController()
    let appStoreVC2 = SKStoreProductViewController()
    
    var document: Document!
    var documentWasNewlyCreated: Bool = false
    #if targetEnvironment(macCatalyst)
    let macToolbarDelegate = MacToolbarDelegate()
    #endif
    var detailVC: EditorDetailViewController!
    var paletteCollectionVC: PaletteCollectionViewController!
    var externalWindow: UIWindow?
    var toolbarViewHeightConstraint: NSLayoutConstraint?
    weak var presentationImageView: UIImageView? {
        didSet {
            canvasViewDrawingDidChange(canvasView)
        }
    }
    var currentBrushWidth: Int? {
        get {
            switch canvasView.documentController?.tool ?? PencilTool(width: 1) {
            case let pencil as PencilTool:
                return pencil.width
            case let eraser as EraserTool:
                return eraser.width
            case let highlight as HighlightTool:
                return highlight.width
            case let shadow as ShadowTool:
                return shadow.width
            default:
                return nil
            }
        }
        set {
            objectWillChange.send()
            updateBrushSize(width: newValue ?? currentBrushWidth ?? 1)
        }
    }
    
    @Published var hoverPoint: PixelPoint?
    @Published var selectedToolIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSidebarButton(viewSize: view.bounds.size)
        
        navigationItem.customizationIdentifier = "editor"
        navigationItem.centerItemGroups = [
            UIBarButtonItem(title: "Flip Vertical", image: UIImage(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down"), primaryAction: .init(handler: { (_) in
                self.canvasView.documentController.flip(vertically: true)
            })).creatingOptionalGroup(customizationIdentifier: "flipVertical", isInDefaultCustomization: false),
            
            UIBarButtonItem(title: "Flip Horizontal", image: UIImage(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right"), primaryAction: .init(handler: { (_) in
                self.canvasView.documentController.flip(vertically: false)
            })).creatingOptionalGroup(customizationIdentifier: "flipHorizontal", isInDefaultCustomization: true),
            
            UIBarButtonItem(title: "Rotate", image: UIImage(systemName: "rotate.left"), primaryAction: .init(handler: { (_) in
                self.canvasView.documentController.rotate(to: .left)
            })).creatingOptionalGroup(customizationIdentifier: "rotateLeft", isInDefaultCustomization: true),
            
            UIBarButtonItem(title: "Posterize", image: UIImage(systemName: "wand.and.stars.inverse"), primaryAction: .init(handler: { (_) in
                self.canvasView.documentController.posterize()
            })).creatingOptionalGroup(customizationIdentifier: "posterize", isInDefaultCustomization: true),
            
            UIBarButtonItemGroup.optionalGroup(customizationIdentifier: "outline", isInDefaultCustomization: false, representativeItem: UIBarButtonItem(title: "Outline", image: UIImage(systemName: "circle.circle")), items: [
                UIBarButtonItem(title: "Outline With Brush Color", image: UIImage(systemName: "pencil.circle"), primaryAction: .init(handler: { (_) in
                    self.canvasView.documentController.outline(colorComponents: self.canvasView.documentController.toolColorComponents)
                })),
                UIBarButtonItem(title: "Outline With Automatic Colors", image: UIImage(systemName: "circle"), primaryAction: .init(handler: { (_) in
                    self.canvasView.documentController.outline()
                }))
            ]),
            
            UIBarButtonItemGroup.optionalGroup(customizationIdentifier: "canvas", representativeItem: UIBarButtonItem(title: "Canvas", image: UIImage(systemName: "square")), items: [
                UIBarButtonItem(title: "Tile Grid", image: UIImage(systemName: "squareshape.split.2x2"), primaryAction: .init(handler: { (_) in
                    self.canvasView.tileGridEnabled.toggle()
                    self.updateControls()
                })),
                UIBarButtonItem(title: "Pixel Grid", image: UIImage(systemName: "squareshape.split.3x3"), primaryAction: .init(handler: { (_) in
                    self.canvasView.pixelGridEnabled.toggle()
                    self.updateControls()
                })),
                UIBarButtonItem(title: "Symmetry", image: UIImage(systemName: "square.split.2x1"), primaryAction: .init(handler: { (_) in
                    self.canvasView.documentController.verticalSymmetry.toggle()
                    self.updateControls()
                }))
            ]),
            
            UIBarButtonItem(title: "Settings", image: UIImage(systemName: "gear"), primaryAction: .init(handler: { (_) in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })).creatingOptionalGroup(customizationIdentifier: "settings", isInDefaultCustomization: true),
            UIBarButtonItem(title: "Help", image: UIImage(systemName: "questionmark.circle"), primaryAction: .init(handler: { (_) in
                let helpVC = UIHostingController(rootView: HelpView(editorVC: self))
                helpVC.modalPresentationStyle = .formSheet
                self.present(helpVC, animated: true, completion: nil)
            })).creatingOptionalGroup(customizationIdentifier: "help", isInDefaultCustomization: true),
        ]
        
        navigationItem.style = .editor
        navigationItem.titleMenuProvider = { suggestedActions in
            UIMenu(children: suggestedActions)
        }
        navigationItem.documentProperties = UIDocumentProperties(url: document.fileURL)
        navigationItem.documentProperties?.activityViewControllerProvider = {
            self.makeShareSheet(asPNG: true, backgroundColor: nil, scale: 1) ?? UIActivityViewController(activityItems: [], applicationActivities: nil)
        }
        
        let screenScale = view.window?.screen.scale ?? UIScreen.main.scale
        toolStackBorder.frame = CGRect(x: 0, y: 0, width: 9999.0, height: 1.0/screenScale)
        toolbarView.layer.addSublayer(toolStackBorder)
        toolbarView.isUserInteractionEnabled = false
        canvasView.layer.magnificationFilter = .nearest
        
        let toolbarVC = UIHostingController(rootView: BottomToolbarView(editorVC: self))
        toolbarVC.view.translatesAutoresizingMaskIntoConstraints = false
        toolbarVC.view.backgroundColor = nil
        toolbarView.addSubview(toolbarVC.view)
        addChild(toolbarVC)
        toolbarViewHeightConstraint = toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: bottomToolbarHeight(viewWidth: view.bounds.width))
        NSLayoutConstraint.activate([
            toolbarViewHeightConstraint!,
            
            toolbarVC.view.topAnchor.constraint(equalTo: toolbarView.topAnchor),
            toolbarVC.view.bottomAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            toolbarVC.view.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor),
            toolbarVC.view.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.screenDidConnect), name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.dismissShareOptions), name: NSNotification.Name(rawValue: "dismissShareOptions"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showShareSheet), name: NSNotification.Name(rawValue: "showShareSheet"), object: nil)
        
        document.open(completionHandler: { (success) in
            if success {
                let documentTitle = self.document?.fileURL.deletingPathExtension().lastPathComponent
                self.title = documentTitle
                self.view.window?.windowScene?.title = documentTitle
                switch self.document.fileType {
                case "public.png", "public.jpeg":
                    self.load()
                default:
                    break
                }
            } else {
                self.spinner.stopAnimating()
                
                let alert = UIAlertController(title: NSLocalizedString("Import Failed", comment: ""), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        toolStackBorder.backgroundColor = UIColor.opaqueSeparator.cgColor
        
        if traitCollection.horizontalSizeClass == .compact {
            navigationItem.leftBarButtonItems?[0] = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(spritesTapped))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if canvasView.documentController?.context != nil {
            canvasView.zoomToFit()
        }
        #if targetEnvironment(macCatalyst)
        navigationController?.navigationBar.isHidden = true
        if let titlebar = view.window?.windowScene?.titlebar {
            let toolbar = NSToolbar(identifier: "toolbar")
            macToolbarDelegate.delegate = self
            toolbar.delegate = macToolbarDelegate
            toolbar.allowsUserCustomization = true
            toolbar.displayMode = .iconOnly
            
            titlebar.titleVisibility = .visible
            titlebar.toolbar = toolbar
        }
        view.window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 900, height: 600)
        view.window?.windowScene?.sizeRestrictions?.maximumSize = CGSize(width: 9999, height: 9999)
        #endif
        
        if !documentWasNewlyCreated, UserDefaults.standard.bool(forKey: UserDefaults.Key.showPermanentEditWarning) {
            UserDefaults.standard.set(false, forKey: UserDefaults.Key.showPermanentEditWarning)
            let alert = UIAlertController(title: NSLocalizedString("Permanent Edits", comment: ""), message: NSLocalizedString("While drawing you can undo edits. Closing the sprite saves edits permanently.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
                self.dismiss(animated: true) {
                    self.document?.close(completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Ask To Save", comment: ""), style: .default, handler: { (_) in
                UserDefaults.standard.set(false, forKey: UserDefaults.Key.autosave)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Continue", comment: ""), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        externalWindow = nil
    }
    
    func load() {
        
        func addImageColorsToRecentColors() {
            let context = self.canvasView.documentController.context!
            var colorsComponents = [ColorComponents]()
            // Backwords to put recent colors in order of image
            loop:
            for x in stride(from: Int(Double(context.width)*0.75), to: Int(Double(context.width)*0.25), by: -1) {
                for y in stride(from: Int(Double(context.height)*0.75), to: Int(Double(context.height)*0.25), by: -1) {
                    let components = self.canvasView.documentController.getColorComponents(at: PixelPoint(x: x, y: y))
                    if components.opacity == 255, !colorsComponents.contains(components) {
                        colorsComponents.append(components)
                        if paletteCollectionVC.maxRecentColorCount <= colorsComponents.count {
                            break loop
                        }
                    }
                }
            }
            for components in colorsComponents {
                paletteCollectionVC.usedColor(components: components)
            }
        }
        
        guard let image = UIImage(data: document.fileData) else {
            self.spinner.stopAnimating()
            let alert = UIAlertController(title: NSLocalizedString("Import Failed", comment: ""), message: NSLocalizedString("Failed to create image from data.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        guard Int(image.size.width) <= SpriteSize.maxSize.width, Int(image.size.height) <= SpriteSize.maxSize.height else {
            self.spinner.stopAnimating()
            let alert = UIAlertController(title: NSLocalizedString("Import Failed", comment: ""), message: NSLocalizedString("Image is too large. (Max. \(SpriteSize.maxSize.width) x \(SpriteSize.maxSize.height))", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(documentStateChanged), name: UIDocument.stateChangedNotification, object: nil)
        
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: .zero)
        
        let canvasBackgroundColor = UserDefaults.standard.string(forKey: UserDefaults.Key.canvasBackgroundColor)
        switch canvasBackgroundColor {
        case "white":
            canvasView.checkerboardColor1 = UIColor(white: 1.0, alpha: 1.0)
            canvasView.checkerboardColor2 = UIColor(white: 0.93, alpha: 1.0)
        case "pink":
            canvasView.checkerboardColor1 = .systemPink
            canvasView.checkerboardColor2 = .systemPink.withAlphaComponent(0.9)
        case "green":
            canvasView.checkerboardColor1 = .systemGreen
            canvasView.checkerboardColor2 = .systemGreen.withAlphaComponent(0.9)
        default:
            break
        }
        
        canvasView.canvasDelegate = self
        canvasView.nonDrawingFingerAction = CanvasView.FingerAction(rawValue: UserDefaults.standard.string(forKey: UserDefaults.Key.fingerAction)!) ?? .ignore
        canvasView.twoFingerUndoEnabled = UserDefaults.standard.bool(forKey: UserDefaults.Key.twoFingerUndoEnabled)
        canvasView.documentController.undoManager = document.undoManager
        canvasView.documentController.palette = {
            if let nameString = UserDefaults.standard.string(forKey: UserDefaults.Key.colorPalette) {
                return Palette.allPalettes.first(where: { $0.name == nameString }) ?? Palette.defaultPalette
            } else {
                return Palette.defaultPalette
            }
        }()
        if let hex = UserDefaults.standard.string(forKey: UserDefaults.Key.currentColor), let color = ColorComponents(hex: hex) {
            canvasView.documentController.toolColorComponents = color
        }
        canvasView.documentController.recentColorDelegate = paletteCollectionVC
        canvasView.documentController.toolDelegate = self
        canvasView.documentController.editorDelegate = self
        canvasView.documentController.context = UIGraphicsGetCurrentContext()
        detailVC.documentController = canvasView.documentController
        detailVC.paletteDelegate = self
        
        toolbarView.isUserInteractionEnabled = true
        selectTool(canvasView.tool)
        paletteCollectionVC.paletteDelegate = self

        canvasView.setupView()
        canvasView.refreshGrid()

        if 1 < UIScreen.screens.count {
            prepareScreen(UIScreen.screens.last!)
        }
        spinner.stopAnimating()
        addImageColorsToRecentColors()
        
        #if !targetEnvironment(macCatalyst)
        document.userActivity?.requiredUserInfoKeys = [UIDocument.userActivityURLKey]
        document.userActivity?.isEligibleForPrediction = true
        document.userActivity?.isEligibleForSearch = true
        document.userActivity?.becomeCurrent()
        #endif
    }
    
    // MARK: - Funcs
    
    func refreshUndo() {
        undoButton.isEnabled = document.undoManager.canUndo
        redoButton.isEnabled = document.undoManager.canRedo
        if let image = canvasView.documentController.context.makeImage(), let data = UIImage(cgImage: image).pngData() {
            document?.fileData = data
        }
    }
    
    func loadAppStorePage(id: AppID) {
        appStoreVC.delegate = self
        appStoreVC.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: id.rawValue]) { (result, error) in
            print(error?.localizedDescription)
        }
    }
    func showAppStorePage() {
        presentedViewController?.present(appStoreVC, animated: true, completion: nil)
    }
    func loadAppStorePage2(id: AppID) {
        appStoreVC2.delegate = self
        appStoreVC2.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: id.rawValue]) { (result, error) in
            print(error?.localizedDescription)
        }
    }
    func showAppStorePage2() {
        presentedViewController?.present(appStoreVC2, animated: true, completion: nil)
    }
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func selectTool(_ tool: Tool) {
        let index: Int
        switch tool {
        case is PencilTool:
            index = 0
        case is EraserTool:
            index = 1
        case is FillTool:
            index = 2
        case is MoveTool:
            index = 3
        case is HighlightTool:
            index = 4
        case is ShadowTool:
            index = 5
        case is EyedroperTool:
            index = 6
        default:
            index = 0
        }
        selectedToolIndex = index
        detailVC.toolSelected(tool: tool)
    }
    
    func eyedropColor(colorComponents components: ColorComponents, at point: PixelPoint) {
        let color = UIColor(components: components)
        
        func hex(components: ColorComponents) -> String {
            return String(format: "#%02X%02X%02X", components.red, components.green, components.blue)
        }
        
        func enlargePixel() {
            let scale = canvasView.spriteZoomScale
            let origin = CGPoint(x: CGFloat(point.x) * scale, y: CGFloat(point.y) * scale)
            let colorPreview = UIView(frame: CGRect(origin: origin, size: CGSize(width: scale, height: scale)))
            colorPreview.backgroundColor = color
            colorPreview.cornerRadius = 0.3
            colorPreview.layer.borderWidth = 0.1
            colorPreview.layer.borderColor = UIColor.separator.cgColor
            canvasView.checkerboardView.addSubview(colorPreview)
            UIView.animate(withDuration: 0.75, animations: {
                colorPreview.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
                colorPreview.alpha = 0.0
            }) { (done) in
                colorPreview.removeFromSuperview()
            }
        }
        
        enlargePixel()
        
        let showColorNotifications = UserDefaults.standard.bool(forKey: UserDefaults.Key.showColorNotifications)
        if showColorNotifications {
            let request = AppNotificationRequest(title: hex(components: components), color: color)
            view.window?.showAppNotification(request)
        }
        
        selectedColorDidChange(colorComponents: components)
        paletteCollectionVC.selectedColor = components
        paletteCollectionVC.collectionView.reloadData()
    }
    
    func updateControls() {
        canvasView.refreshGrid()
//        if UserDefaults.standard.bool(forKey: UserDefaults.Key.showPalette) {
            paletteCollectionVC.loadPalette(canvasView.documentController.palette ?? Palette.defaultPalette)
//        }
    }
    
    @IBAction func spritesTapped() {
        if UserDefaults.standard.bool(forKey: UserDefaults.Key.autosave) || !document.undoManager.canUndo {
            closeDocument()
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Save Changes?", comment: ""), message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Discard Changes", comment: ""), style: .destructive, handler: { (_) in
                while self.document.undoManager.canUndo {
                    self.document.undoManager.undo()
                }
                self.closeDocument()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default, handler: { (_) in
                self.closeDocument()
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func closeDocument() {
        dismiss(animated: true) {
            self.document?.close(completionHandler: { (success) in
                if self.documentWasNewlyCreated, !self.document.undoManager.canUndo {
                    // Empty sprite
                    let createdDocumentsCount = UserDefaults.standard.integer(forKey: UserDefaults.Key.createdDocumentsCount)
                    UserDefaults.standard.set(createdDocumentsCount-1, forKey: UserDefaults.Key.createdDocumentsCount)
                    UserDefaults.standard.set(String(createdDocumentsCount-1), forKey: UserDefaults.Key.createdDocumentsCountText)
                    do {
                        try FileManager.default.removeItem(at: self.document.fileURL)
                    } catch {
                        print("Couldn't delete new empty sprite.")
                    }
                }
            })
            let documentsClosedCount = UserDefaults.standard.integer(forKey: UserDefaults.Key.documentsClosedCount)
            switch documentsClosedCount {
            case 10, 50:
                if let ws = self.view.window?.windowScene {
                    SKStoreReviewController.requestReview(in: ws)
                }
            default:
                break
            }
            UserDefaults.standard.set(documentsClosedCount + 1, forKey: UserDefaults.Key.documentsClosedCount)
        }
    }

    @IBAction func undoTapped() {
        canvasView.doUndo()
	}
    @IBAction func redoTapped() {
        canvasView.doRedo()
    }
    
    @IBAction func shareTapped(_ sender: UIBarButtonItem) {
        doShareButtonAction(button: sender)
    }
    func doShareButtonAction(button: UIBarButtonItem?) {
        if traitCollection.horizontalSizeClass == .regular {
            let shareVC = UIHostingController(rootView: ShareOptionsView())
            shareVC.modalPresentationStyle = .popover
            shareVC.preferredContentSize = CGSize(width: 320, height: 230)
            if let sender = button {
                shareVC.popoverPresentationController?.barButtonItem = sender
            } else {
                shareVC.popoverPresentationController?.sourceView = autoSplitViewController?.view
                shareVC.popoverPresentationController?.sourceRect = CGRect(x: autoSplitViewController!.view.bounds.maxX - 200, y: 72, width: 0, height: 0)
            }
            present(shareVC, animated: true, completion: nil)
        } else {
            let shareVC = UIHostingController(rootView: BottomSheetView())
            shareVC.view.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
            shareVC.modalPresentationStyle = .overFullScreen
            present(shareVC, animated: false, completion: nil)
        }
    }
    @objc func dismissShareOptions(notification: Notification) {
        presentedViewController?.dismiss(animated: false, completion: nil)
    }
    private func makeShareSheet(asPNG: Bool, backgroundColor: UIColor?, scale: CGFloat) -> UIActivityViewController? {
        guard let uiImage = canvasView.documentController.export(scale: scale, backgroundColor: backgroundColor) else { return nil }
        
        let shareImage: Any
        if asPNG {
            shareImage = uiImage
        } else {
            shareImage = uiImage.jpegData(compressionQuality: 0.85) ?? uiImage
        }
        let previewScale: CGFloat = (canvasView.documentController.context.width * canvasView.documentController.context.height) <= (32*32) ? 4 : 2
        let previewImage = canvasView.documentController.export(scale: previewScale, backgroundColor: backgroundColor)
        
        let items: [Any] = [shareImage, ShareTextSource(image: previewImage, documentURL: document.fileURL)]
        return UIActivityViewController(activityItems: items, applicationActivities: [SaveAsPaletteActivity(), SetWidgetSpriteActivity()])
    }
    @objc func showShareSheet(notification: Notification) {
        presentedViewController?.dismiss(animated: false, completion: nil)
        
        let asPNG = notification.userInfo?["asPNG"] as? Bool ?? true
        let backgroundColor = notification.userInfo?["backgroundColor"] as? UIColor
        let scale = notification.userInfo?["scale"] as? CGFloat ?? 1.0
        
        if let shareSheet = makeShareSheet(asPNG: asPNG, backgroundColor: backgroundColor, scale: scale) {
            shareSheet.popoverPresentationController?.barButtonItem = shareButton
            present(shareSheet, animated: true, completion: nil)
        }
    }
    
    @IBAction func sidebarButtonTapped(_ sender: Any) {
        doSidebarButtonAction()
    }
    func doSidebarButtonAction() {
        autoSplitViewController?.showDetail.toggle()
    }
    
    func showPaletteChooser() {
        let paletteVC = UIHostingController(rootView: PalettePickerView(editorDetailVC: detailVC))
        paletteVC.modalPresentationStyle = .formSheet
        present(paletteVC, animated: true, completion: nil)
    }
    
    func selectedColorDidChange(colorComponents components: ColorComponents) {
        canvasView.documentController.toolColorComponents = components
        if !(canvasView.tool is FillTool) {
            canvasView.tool = canvasView.documentController.pencilTool
        }
        UserDefaults.standard.set(components.hex, forKey: UserDefaults.Key.currentColor)
    }
    
    func canvasViewDidBeginUsingTool(_ canvasView: CanvasView) {
        
    }
    func canvasViewDidEndUsingTool(_ canvasView: CanvasView) {
        
    }
    func canvasViewDrawingDidChange(_ canvasView: CanvasView) {
        presentationImageView?.image = UIImage(cgImage: canvasView.documentController.context.makeImage()!)
    }
    func canvasViewDidFinishRendering(_ canvasView: CanvasView) {
        
    }
    func showColorPalette() {
        doSidebarButtonAction()
    }
    
    @objc func documentStateChanged(notification: Notification) {
        switch document.documentState {
        case .inConflict:
            let alert = UIAlertController(title: NSLocalizedString("Document Conflict", comment: ""), message: NSLocalizedString("The document was changed in iCloud.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        case .savingError:
            let alert = UIAlertController(title: NSLocalizedString("Saving Error", comment: ""), message: NSLocalizedString("The document could not be saved.", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        default:
            break
        }
    }
    
    @objc func screenDidConnect(notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }
        prepareScreen(screen)
    }
    
    func prepareScreen(_ screen: UIScreen) {
        externalWindow = UIWindow(frame: screen.bounds)
        externalWindow?.screen = screen
        if let presentationVC = storyboard?.instantiateViewController(withIdentifier: "presentation") as? DocumentPresentationViewController {
            externalWindow?.rootViewController = presentationVC
            presentationVC.loadView()
            presentationVC.viewDidLoad()
            presentationImageView = presentationVC.imageView
            externalWindow?.isHidden = false
        }
    }
    
    func updateBrushSize(width: Int) {
        switch canvasView.documentController.tool {
        case is PencilTool:
            let finalWidth = min(width, 10)
            canvasView.documentController.pencilTool.width = finalWidth
            canvasView.documentController.tool = canvasView.documentController.pencilTool
            canvasView.documentController.canvasView.toolSizeChanged(size: PixelSize(width: finalWidth, height: finalWidth))
        case is EraserTool:
            let finalWidth = min(width, 10)
            canvasView.documentController.eraserTool.width = finalWidth
            canvasView.documentController.tool = canvasView.documentController.eraserTool
            canvasView.documentController.canvasView.toolSizeChanged(size: PixelSize(width: finalWidth, height: finalWidth))
        case is HighlightTool:
            let finalWidth = min(width, 5)
            canvasView.documentController.highlightTool.width = finalWidth
            canvasView.documentController.tool = canvasView.documentController.highlightTool
            canvasView.documentController.canvasView.toolSizeChanged(size: PixelSize(width: finalWidth, height: finalWidth))
        case is ShadowTool:
            let finalWidth = min(width, 5)
            canvasView.documentController.shadowTool.width = finalWidth
            canvasView.documentController.tool = canvasView.documentController.shadowTool
            canvasView.documentController.canvasView.toolSizeChanged(size: PixelSize(width: finalWidth, height: finalWidth))
        default:
            break
        }
    }
    
    func updateSidebarButton(viewSize: CGSize) {
        if viewSize.width < viewSize.height {
            sidebarButton.setImage(UIImage(systemName: "squares.below.rectangle"), for: .normal)
        } else {
            sidebarButton.setImage(UIImage(systemName: "sidebar.right"), for: .normal)
        }
    }
    
    func bottomToolbarHeight(viewWidth: CGFloat) -> CGFloat {
        viewWidth < BottomToolbarView.minWidthNeededForSingleRowBar ? -96 : -52
    }
    
    @objc func doneTapped() {
        view.endEditing(true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateSidebarButton(viewSize: size)
        if canvasView.documentController?.context != nil {
            canvasView.zoomToFit() // For macOS
        }
        toolbarViewHeightConstraint?.constant = bottomToolbarHeight(viewWidth: size.width)
    }
    
}

#if targetEnvironment(macCatalyst)
extension EditorViewController: MacToolbarActionsDelegate {
    
    var documentMenu: UIMenu? {
        UIMenu(children: [
            UIAction(title: "V Symmetry", image: UIImage(systemName: "square.split.2x1")) { _ in
                self.vSymmetryClicked()
            },
            UIAction(title: "H Symmetry", image: UIImage(systemName: "square.split.1x2")) { _ in
                self.hSymmetryClicked()
            }
        ])
    }
    
    func spritesClicked(_ sender: UIBarButtonItem) {
        spritesTapped()
    }
    func shareClicked(_ sender: UIBarButtonItem) {
        doShareButtonAction(button: nil)
    }
    func choosePaletteClicked(_ sender: UIBarButtonItem) {
        detailVC.doChoosePalette(button: nil)
    }
    func sidebarButtonClicked(_ sender: UIBarButtonItem) {
        doSidebarButtonAction()
    }
    func vSymmetryClicked() {
        canvasView.documentController.verticalSymmetry.toggle()
    }
    func hSymmetryClicked() {
        canvasView.documentController.horizontalSymmetry.toggle()
    }
    func pixelGridClicked() {
        canvasView.pixelGridEnabled.toggle()
    }
    func tileGridClicked() {
        canvasView.tileGridEnabled.toggle()
    }
    
}
#endif
