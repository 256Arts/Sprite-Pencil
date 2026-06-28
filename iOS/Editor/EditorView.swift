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
    @State private var selectedTool: EditorTool = .pencil
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

    // Coalesces document re-encodes. The kit fires `.drawingDidChange` on every
    // touch-move sample, so encoding the full PNG inline on each one stutters
    // larger canvases. Instead we keep at most one encode in flight and re-run
    // once more if the canvas changed meanwhile, so the final state is always saved.
    @State private var isEncodingDocument = false
    @State private var documentNeedsReencode = false
    
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
            checkerboardColor1: canvasBackground.checkerColors.base,
            checkerboardColor2: canvasBackground.checkerColors.alternate,
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

                    // Seed recent colors now that the context exists. `configure`
                    // runs once, exactly when the context is first set, so this is
                    // the precise readiness signal (vs. guessing with a delay). The
                    // `Task` hop keeps the `paletteController` mutation off this
                    // view-update pass (see `refreshDocumentDataFromContext`).
                    Task { @MainActor in addImageColorsToRecentColors() }
                }

                canvasView.tool = documentController.pencilTool
            }
        )
        .safeAreaInset(edge: .bottom) {
            // Compact stacks the edge items above the tool bar; regular has the
            // horizontal room to overlay the centered tool bar on top of them.
            // `AnyLayout` (vs. an if/else) keeps the subviews' identity across a
            // size-class change, so their state survives rotation / Split View.
            let layout = horizontalSizeClass == .compact ? AnyLayout(VStackLayout()) : AnyLayout(ZStackLayout())
            layout {
                leadingAndTrailingBottomBarItems()

                ToolSelectionBar(selectedTool: $selectedTool)
            }
            .padding(6)
        }
        .safeAreaPadding(.bottom, horizontalSizeClass == .compact && showingInspector && inspectorDetent == .height(Self.inspectorPeekDetentHeight) ? Self.inspectorPeekDetentHeight : 0)
        .toolbar {
            // Keep Undo away from the document's close button (also leading), so
            // reaching for Undo doesn't accidentally exit the document.
            ToolbarSpacer(.fixed, placement: .topBarLeading)
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
                
                Menu("Rotate", systemImage: "rotate.left") {
                    Button("Rotate Left", systemImage: "rotate.left") {
                        documentController.rotate(to: .left)
                    }
                    Button("Rotate Right", systemImage: "rotate.right") {
                        documentController.rotate(to: .right)
                    }
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
                        .onChange(of: documentController.verticalSymmetry) { _, _ in
                            canvasRef?.refreshGrid()
                        }
                    Toggle("Horizontal Symmetry", systemImage: "square.split.1x2", isOn: $documentController.horizontalSymmetry)
                        .onChange(of: documentController.horizontalSymmetry) { _, _ in
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
        }
        .onDisappear {
            documentsClosedCount += 1
        }
        .onChange(of: selectedTool) { _, newTool in
            guard let canvasRef else { return }
            canvasRef.tool = newTool.tool(in: documentController)
            // Reflect the new tool's brush width, or hide the stepper (nil) for
            // tools that have no width (fill, move, eyedropper).
            currentBrushWidth = newTool.sizableTool(in: documentController)?.width
        }
        .onChange(of: currentBrushWidth) { _, width in
            // Apply the stepper's value to the active tool. `selectedTool` is the
            // source of truth for which tool the stepper drives, and assigning the
            // controller's tool pushes the new size to the canvas (see EditorTool).
            guard let width else { return }
            selectedTool.setWidth(width, in: documentController)
        }
        .onChange(of: documentController.brushShape) { _, _ in
            // Re-render the hover outline (square vs. round) for the active brush.
            guard let canvasRef, let width = currentBrushWidth else { return }
            canvasRef.toolSizeChanged(size: PixelSize(width: width, height: width))
        }
        .onChange(of: documentController.toolColorComponents) { _, newColor in
            // Persist the active color so it's restored next launch (see `init`)
            // and so the widget can pick it up as a background (see ShareOptionsView).
            // Catches every path that changes the color: picker, eyedropper, palette tap.
            currentColorHex = newColor.hex
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
                maxBrushWidth: selectedTool.sizableTool(in: documentController)?.maxWidth ?? 10,
                colorGet: { Color(components: documentController.toolColorComponents) },
                colorSet: { newColor in
                    documentController.toolColorComponents = ColorComponents(newColor)
                }
            )
        }
    }

    // MARK: - Helpers

    private var canvasBackground: CanvasBackground {
        CanvasBackground(storageValue: canvasBackgroundColorKey)
    }

    private var currentPalette: Palette {
        if !colorPaletteName.isEmpty {
            Palette.allPalettes.first(where: { $0.name == colorPaletteName }) ?? Palette.defaultPalette
        } else {
            Palette.defaultPalette
        }
    }

    private func refreshDocumentDataFromContext() {
        // Coalesce bursts: if an encode is already scheduled/running, just mark the
        // canvas dirty so one final encode runs when it finishes.
        guard !isEncodingDocument else {
            documentNeedsReencode = true
            return
        }
        isEncodingDocument = true
        documentNeedsReencode = false

        // A `Task` hop also keeps this off the view-update pass (mutating during
        // a view update crashes), and re-snapshots the latest context each run.
        Task { @MainActor in
            defer {
                isEncodingDocument = false
                if documentNeedsReencode {
                    refreshDocumentDataFromContext()
                }
            }
            guard let ctx = documentController.context, let image = ctx.makeImage(),
                  let data = UIImage(cgImage: image).pngData() else { return }
            document.data = data
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

