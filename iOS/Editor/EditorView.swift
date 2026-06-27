import Combine
import SpritePencilKit
import SwiftUI
import UIKit

struct EditorView: View {
    
    @Binding var document: SpriteImageDocument

    @Environment(\.undoManager) private var undoManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Canvas configuration state (mirrors prior defaults/controls)
    @AppStorage(UserDefaults.Key.showPixelGrid) private var pixelGridEnabled: Bool = false
    @AppStorage(UserDefaults.Key.showTileGrid) private var tileGridEnabled: Bool = false
    @AppStorage(UserDefaults.Key.twoFingerUndoEnabled) private var twoFingerUndoEnabled: Bool = false
    @AppStorage(UserDefaults.Key.fingerAction) private var fingerActionRaw: String = "ignore"
    private var nonDrawingFingerAction: CanvasUIView.FingerAction {
        get { CanvasUIView.FingerAction(rawValue: fingerActionRaw) ?? .ignore }
        set { fingerActionRaw = newValue.rawValue }
    }
    
    static let inspectorPeekDetentHeight: CGFloat = 200

    // Bottom toolbar state
    @State private var selectedToolIndex: Int = 0
    @State private var currentBrushWidth: Int? = 1

    // Additional @AppStorage properties for UserDefaults keys used later
    @AppStorage(UserDefaults.Key.currentColor) private var currentColorHex: String = ""
    @AppStorage(UserDefaults.Key.canvasBackgroundColor) private var canvasBackgroundColorKey: String = ""
    @AppStorage(UserDefaults.Key.colorPalette) private var colorPaletteName: String = ""
    @AppStorage(UserDefaults.Key.documentsClosedCount) private var documentsClosedCount: Int = 0

    // Palette controller bridged into SwiftUI Inspector
    @State private var paletteController = PaletteCollectionController()
    
    @State private var documentController = DocumentController()

    // Hold a weak reference to the underlying `CanvasUIView` to drive imperative actions from toolbar
    @State private var canvasRef: CanvasUIView?
    
    @State private var showingInspector = true
    @State private var inspectorDetent: PresentationDetent = .height(Self.inspectorPeekDetentHeight)
    @State private var isSavePalettePresented = false
    @State private var pendingPalette: Palette?
    
    @State private var subscriptions: Set<AnyCancellable> = []
    
    init(document: Binding<SpriteImageDocument>) {
        self._document = document

        // Palette & current color
        documentController.palette = currentPalette
        paletteController.palette = currentPalette
        if let color = ColorComponents(hex: currentColorHex), !currentColorHex.isEmpty {
            documentController.toolColorComponents = color
        }
    }

    var body: some View {
        ZoomableCanvasView(
            documentController: documentController,
            zoomEnabled: true,
            pixelGridEnabled: pixelGridEnabled,
            tileGridEnabled: tileGridEnabled,
            checkerboardColor1: checker1,
            checkerboardColor2: checker2,
            tileGridColor: .systemGray3,
            pixelGridColor: .systemGray3,
            twoFingerUndoEnabled: twoFingerUndoEnabled,
            applePencilCanEyedrop: true,
            nonDrawingFingerAction: nonDrawingFingerAction,
            shouldFillPaths: false,
            onEvent: { event in
                switch event {
                case .drawingDidChange, .didEndUsingTool:
                    refreshDocumentDataFromContext()
                case .showColorPalette:
                    // Could present palette UI here if desired
                    break
                default:
                    break
                }
            },
            configure: { zoomableView in
                let canvasView = zoomableView.contentView
                
                // Keep a reference for toolbar actions
                self.canvasRef = canvasView
                
                documentController.zoomableView = zoomableView
                documentController.canvasView = canvasView
                
                // Initialize drawing context from document image data
                if let image = UIImage(data: document.data), let context = CGContext.spriteDrawingContext(from: image) {
                    documentController.context = context
                    documentController.refresh()
                    canvasView.makeCheckerboard()
                    canvasView.refreshGrid()
                    zoomableView.zoomToFit()
                }

                canvasView.tool = documentController.pencilTool
            }
        )
        .safeAreaInset(edge: .bottom) {
            if horizontalSizeClass == .compact {
                VStack {
                    leadingAndTrailingBottomBarItems()
                    
                    ToolSelectionBar(selectedToolIndex: $selectedToolIndex)
                }
                .padding(6)
            } else {
                ZStack {
                    leadingAndTrailingBottomBarItems()
                    
                    ToolSelectionBar(selectedToolIndex: $selectedToolIndex)
                }
                .padding(6)
            }
        }
        .safeAreaPadding(.bottom, horizontalSizeClass == .compact && showingInspector && inspectorDetent == .height(Self.inspectorPeekDetentHeight) ? Self.inspectorPeekDetentHeight : 0)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button("Undo", systemImage: "arrow.uturn.left") { canvasRef?.doUndo() }
                    .disabled(!(undoManager?.canUndo ?? false))
                Button("Redo", systemImage: "arrow.uturn.right") { canvasRef?.doRedo() }
                    .disabled(!(undoManager?.canRedo ?? false))
            }
            
            ToolbarItemGroup {
                Menu("Flip", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right") {
                    Button("Flip Horizontal", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right") {
                        documentController.flip(vertically: false)
                    }
                    Button("Flip Vertical", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down") {
                        documentController.flip(vertically: true)
                    }
                }
                
                Button("Rotate", systemImage: "rotate.left") {
                    documentController.rotate(to: .left)
                }
                
                Menu("Outline", systemImage: "circle.circle") {
                    Button("Outline With Brush Color", systemImage: "pencil.circle") {
                        documentController.outline(colorComponents: documentController.toolColorComponents)
                    }
                    Button("Outline With Automatic Colors", systemImage: "circle") {
                        documentController.outline()
                    }
                }
                
                Menu("Canvas", systemImage: "square") {
                    Button("Trim Canvas", systemImage: "crop") {
                        documentController.trimCanvas()
                    }
                    Divider()
                    Toggle("Pixel Grid", systemImage: "squareshape.split.3x3", isOn: $pixelGridEnabled)
                    Toggle("Tile Grid", systemImage: "squareshape.split.2x2", isOn: $tileGridEnabled)
                    Divider()
                    Toggle("Vertical Symmetry", systemImage: "square.split.2x1", isOn: $documentController.verticalSymmetry)
                        .onChange(of: documentController.verticalSymmetry) { _, newValue in
                            documentController.verticalSymmetry = newValue
                            canvasRef?.refreshGrid()
                        }
                    Toggle("Horizontal Symmetry", systemImage: "square.split.1x2", isOn: $documentController.horizontalSymmetry)
                        .onChange(of: documentController.horizontalSymmetry) { _, newValue in
                            documentController.horizontalSymmetry = newValue
                            canvasRef?.refreshGrid()
                        }
                }
            }
            
            ToolbarSpacer(.fixed)
            
            ToolbarItemGroup {
                Menu("Share", systemImage: "square.and.arrow.up") {
                    ShareOptionsView(documentController: documentController)
                    Button("Save as Palette", systemImage: "paintpalette") {
                        let image = UIImage(cgImage: documentController.context.makeImage()!)
                        if let palette = Palette(name: NSLocalizedString("My Palette", comment: "default palette name"), image: image, defaultGroupLength: 1) {
                            pendingPalette = palette
                            isSavePalettePresented = true
                        }
                    }
                }
                .popover(isPresented: $isSavePalettePresented) {
                    if let palette = pendingPalette {
                        AddPaletteView(palette: palette, fromLospec: false)
                            .presentationDetents([.medium, .large])
                    }
                }
                
                if horizontalSizeClass == .regular {
                    Button("Palettes", systemImage: "sidebar.trailing") {
                        showingInspector.toggle()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .inspector(isPresented: $showingInspector) {
            PaletteCollectionView(
                controller: paletteController,
                showPaletteChooserButton: true,
                selectedColor: $documentController.toolColorComponents
            )
            .presentationDetents([.height(Self.inspectorPeekDetentHeight), .large], selection: $inspectorDetent)
            .presentationBackgroundInteraction(.enabled)
            .inspectorColumnWidth(min: 220, ideal: 280, max: 360)
        }
        .onAppear {
            documentController.undoManager = self.undoManager

            // Subscribe to engine events. The eyedropper reports its picked
            // color here; without this handler the tool reads a color but
            // nothing applies it (it appeared to "do nothing").
            if subscriptions.isEmpty {
                documentController.eventPublisher
                    .sink { event in
                        switch event {
                        case .eyedropColor(let color, point: _):
                            documentController.toolColorComponents = color
                            paletteController.usedColor(components: color)
                        case .usedColor(let color):
                            paletteController.usedColor(components: color)
                        default:
                            break
                        }
                    }
                    .store(in: &subscriptions)
            }

            // Seed palette with image colors once the canvas is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                addImageColorsToRecentColors()
            }
        }
        .onDisappear {
            documentsClosedCount += 1
        }
        .onChange(of: selectedToolIndex) { _, newValue in
            guard let canvas = canvasRef else { return }
            canvas.tool = {
                switch newValue {
                case 0: documentController.pencilTool
                case 1: documentController.eraserTool
                case 2: documentController.fillTool
                case 3: documentController.moveTool
                case 4: documentController.highlightTool
                case 5: documentController.shadowTool
                case 6: documentController.eyedroperTool
                default: documentController.pencilTool
                }
            }()
            // Reflect the new tool's brush width, or hide the stepper (nil) for
            // tools that have no width (fill, move, eyedropper).
            currentBrushWidth = brushWidth(forToolIndex: newValue)
        }
        .onChange(of: currentBrushWidth) { _, width in
            guard let width, let canvasRef else { return }
            
            switch documentController.tool {
            case is PencilTool:
                let finalWidth = min(width, 10)
                documentController.pencilTool.width = finalWidth
                documentController.tool = documentController.pencilTool
                canvasRef.toolSizeChanged(size: PixelSize(width: finalWidth, height: finalWidth))
            case is EraserTool:
                let finalWidth = min(width, 10)
                documentController.eraserTool.width = finalWidth
                documentController.tool = documentController.eraserTool
                canvasRef.toolSizeChanged(size: PixelSize(width: finalWidth, height: finalWidth))
            case is HighlightTool:
                let finalWidth = min(width, 5)
                documentController.highlightTool.width = finalWidth
                documentController.tool = documentController.highlightTool
                canvasRef.toolSizeChanged(size: PixelSize(width: finalWidth, height: finalWidth))
            case is ShadowTool:
                let finalWidth = min(width, 5)
                documentController.shadowTool.width = finalWidth
                documentController.tool = documentController.shadowTool
                canvasRef.toolSizeChanged(size: PixelSize(width: finalWidth, height: finalWidth))
            default:
                break
            }
        }
        .onChange(of: documentController.checkeredDrawingMode) { _, newValue in
            documentController.checkeredDrawingMode = newValue
        }
        .onChange(of: documentController.brushShape) { _, _ in
            // Re-render the hover outline (square vs. round) for the active brush.
            guard let canvasRef, let width = currentBrushWidth else { return }
            canvasRef.toolSizeChanged(size: PixelSize(width: width, height: width))
        }
    }
    
    @ViewBuilder
    private func leadingAndTrailingBottomBarItems() -> some View {
        HStack {
            if let hoverPoint = documentController.hoverPoint {
                Text("\(hoverPoint.x), \(hoverPoint.y)")
                    .font(Font.body.monospacedDigit())
            }
            
            Spacer()
            
            if horizontalSizeClass == .compact, !showingInspector {
                Button("Palettes", systemImage: "paintpalette") {
                    showingInspector.toggle()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
            }
            
            ToolOptionsView(
                currentBrushWidth: $currentBrushWidth,
                ditherOn: $documentController.checkeredDrawingMode,
                roundBrush: Binding(
                    get: { documentController.brushShape == .circle },
                    set: { documentController.brushShape = $0 ? .circle : .square }
                ),
                maxBrushWidth: maxBrushWidth(forToolIndex: selectedToolIndex),
                colorGet: { Color(components: documentController.toolColorComponents) },
                colorSet: { newColor in
                    documentController.toolColorComponents = ColorComponents(newColor)
                }
            )
        }
    }

    // MARK: - Helpers

    /// The current brush width for the tool at `index`, or `nil` for tools that
    /// have no brush width (fill, move, eyedropper) — which hides the stepper.
    private func brushWidth(forToolIndex index: Int) -> Int? {
        switch index {
        case 0: documentController.pencilTool.width
        case 1: documentController.eraserTool.width
        case 4: documentController.highlightTool.width
        case 5: documentController.shadowTool.width
        default: nil
        }
    }

    /// The largest brush width the tool at `index` supports.
    private func maxBrushWidth(forToolIndex index: Int) -> Int {
        switch index {
        case 4, 5: 5 // highlight, shadow
        default: 10  // pencil, eraser
        }
    }

    private var checker1: UIColor {
        let key = canvasBackgroundColorKey
        return switch key {
        case "white": UIColor(white: 1.0, alpha: 1.0)
        case "pink": .systemPink
        case "green": .systemGreen
        default: .systemGray4
        }
    }
    private var checker2: UIColor {
        let key = canvasBackgroundColorKey
        return switch key {
        case "white": UIColor(white: 0.93, alpha: 1.0)
        case "pink": .systemPink.withAlphaComponent(0.9)
        case "green": .systemGreen.withAlphaComponent(0.9)
        default: .systemGray5
        }
    }

    private var currentPalette: Palette {
        if !colorPaletteName.isEmpty {
            Palette.allPalettes.first(where: { $0.name == colorPaletteName }) ?? Palette.defaultPalette
        } else {
            Palette.defaultPalette
        }
    }

    private func refreshDocumentDataFromContext() {
        guard let ctx = documentController.context, let image = ctx.makeImage() else { return }
        
        if let data = UIImage(cgImage: image).pngData() {
            Task {
                // Added `Task` becuase this should not be done during view updates (crash)
                document.data = data
            }
        }
    }

    private func addImageColorsToRecentColors() {
        guard let context = documentController.context else { return }
        
        var colorsComponents = [ColorComponents]()
        // Backwards to put recent colors in order of image
        loop: for x in stride(from: Int(Double(context.width)*0.75), to: Int(Double(context.width)*0.25), by: -1) {
            for y in stride(from: Int(Double(context.height)*0.75), to: Int(Double(context.height)*0.25), by: -1) {
                let components = documentController.getColorComponents(at: PixelPoint(x: x, y: y))
                if components.opacity == 255, !colorsComponents.contains(components) {
                    colorsComponents.append(components)
                    if paletteController.maxRecentColorCount <= colorsComponents.count {
                        break loop
                    }
                }
            }
        }
        for components in colorsComponents {
            paletteController.usedColor(components: components)
        }
    }
}

#Preview {
    EditorView(document: .constant(SpriteImageDocument(size: .defaultSize)))
}

