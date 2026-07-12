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
    @AppStorage(UserDefaults.Key.fingerAction) private var nonDrawingFingerAction: FingerAction = .ignore
    
    static let inspectorPeekDetentHeight: CGFloat = 200

    // Bottom toolbar state
    @State private var selectedTool: EditorTool = .pencil
    @State private var currentBrushWidth: Int? = 1

    // Additional @AppStorage properties for UserDefaults keys used later
    @AppStorage(UserDefaults.Key.currentColor) private var currentColorHex: String = ""
    @AppStorage(UserDefaults.Key.canvasBackgroundColor) private var canvasBackground: CanvasBackground = .default
    @AppStorage(UserDefaults.Key.colorPalette) private var colorPaletteName: String = ""
    @AppStorage(UserDefaults.Key.documentsClosedCount) private var documentsClosedCount: Int = 0

    // Palette controller bridged into SwiftUI Inspector
    @State private var paletteController = PaletteCollectionController()
    
    @State private var documentController = DocumentController()

    @State private var showingInspector = true
    @State private var inspectorDetent: PresentationDetent = .height(Self.inspectorPeekDetentHeight)
    @State private var pendingPalette: Palette?
    @State private var isExportPresented = false
    @State private var isSettingsPresented = false
    @State private var showingPaletteChooser = false

    // Mirrors of `undoManager.canUndo/canRedo`, refreshed on the kit's
    // `.refreshUndo` events so the Undo/Redo buttons update deterministically
    // instead of riding incidental re-renders.
    @State private var canUndo = false
    @State private var canRedo = false

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
                case .eyedropColor(let color, point: _):
                    // The eyedropper reports its picked color here; without
                    // this handler the tool reads a color but nothing applies
                    // it (it appeared to "do nothing").
                    documentController.toolColorComponents = color
                    paletteController.usedColor(components: color)
                case .usedColor(let color):
                    paletteController.usedColor(components: color)
                case .showColorPalette:
                    // Could present palette UI here if desired
                    break
                case .refreshUndo:
                    canUndo = undoManager?.canUndo ?? false
                    canRedo = undoManager?.canRedo ?? false
                default:
                    break
                }
            },
            configure: { _ in
                // Initialize drawing context from document image data. The kit
                // reacts to `loadContext` on its own (checkerboard, grid, fit).
                guard documentController.context == nil,
                      let image = UIImage(data: document.data),
                      let context = CGContext.spriteDrawingContext(from: image) else { return }
                documentController.loadContext(context)

                // Seed recent colors now that the context exists. `configure`
                // runs once, exactly when the context is first set, so this is
                // the precise readiness signal (vs. guessing with a delay). The
                // `Task` hop keeps the `paletteController` mutation off this
                // view-update pass (see `refreshDocumentDataFromContext`).
                Task { @MainActor in addImageColorsToRecentColors() }
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
                Button("Undo", systemImage: "arrow.uturn.left") { documentController.undo() }
                    .disabled(!canUndo)
                Button("Redo", systemImage: "arrow.uturn.right") { documentController.redo() }
                    .disabled(!canRedo)
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
                
                // Only one rotation direction is exposed: rotating is a rare
                // action, so a single button beats a menu. To rotate the other
                // way, tap it three times.
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
                    // The canvas redraws its symmetry guides itself when these change.
                    Toggle("Vertical Symmetry", systemImage: "square.split.2x1", isOn: $documentController.verticalSymmetry)
                    Toggle("Horizontal Symmetry", systemImage: "square.split.1x2", isOn: $documentController.horizontalSymmetry)
                }
            }
            
            ToolbarSpacer(.fixed)
            
            ToolbarItemGroup {
                Menu("Share", systemImage: "square.and.arrow.up") {
                    ShareOptionsView(documentController: documentController, isExportPresented: $isExportPresented)
                    Button("Save as Palette", systemImage: "paintpalette") {
                        let image = UIImage(cgImage: documentController.context.makeImage()!)
                        // Note: `Palette(name:image:)` requires a 1px-tall image, so this
                        // only succeeds for palette-strip sprites — same as before.
                        pendingPalette = Palette(name: NSLocalizedString("My Palette", comment: "default palette name"), image: image, defaultGroupLength: 1)
                    }
                }
                .popover(item: $pendingPalette) { palette in
                    AddPaletteView(palette: palette, fromLospec: false)
                        .presentationDetents([.medium, .large])
                }
                .popover(isPresented: $isExportPresented) {
                    ExportImageView(documentController: documentController)
                }

                Button("Settings", systemImage: "gear") {
                    isSettingsPresented = true
                }

                if horizontalSizeClass == .regular {
                    Button("Palettes", systemImage: "sidebar.trailing") {
                        showingInspector.toggle()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                SettingsView()
            }
        }
        .inspector(isPresented: $showingInspector) {
            PaletteCollectionView(
                controller: paletteController,
                selectedColor: $documentController.toolColorComponents,
                onChoosePalette: { showingPaletteChooser = true }
            )
            .presentationDetents([.height(Self.inspectorPeekDetentHeight), .large], selection: $inspectorDetent)
            .presentationBackgroundInteraction(.enabled)
            .inspectorColumnWidth(min: 220, ideal: 280, max: 360)
        }
        .sheet(isPresented: $showingPaletteChooser) {
            NavigationStack {
                PalettePickerView(selectedPaletteName: paletteController.palette?.name ?? "") { palette in
                    paletteController.palette = palette
                }
            }
        }
        .onAppear {
            documentController.undoManager = self.undoManager
        }
        .onChange(of: undoManager) { _, newManager in
            // The environment's manager can be nil on first render or replaced
            // under DocumentGroup; re-wire the controller whenever it changes.
            documentController.undoManager = newManager
            canUndo = newManager?.canUndo ?? false
            canRedo = newManager?.canRedo ?? false
        }
        .onDisappear {
            documentsClosedCount += 1
        }
        .onChange(of: selectedTool) { _, newTool in
            documentController.tool = newTool.tool(in: documentController)
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
        .onChange(of: paletteController.palette?.name) { _, newName in
            // The palette chooser writes only to the collection controller;
            // push the selection into the engine (Highlight/Shadow shade
            // against it) and persist it for the next launch.
            documentController.palette = paletteController.palette
            colorPaletteName = newName ?? ""
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
            HoverReadout(documentController: documentController)

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

    private var currentPalette: Palette {
        PaletteStore.shared.palette(named: colorPaletteName) ?? PaletteStore.shared.defaultPalette
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

/// Isolated so pointer/Pencil hover samples — which arrive continuously while
/// hovering — re-evaluate only this `Text`, not the entire editor body.
private struct HoverReadout: View {
    var documentController: DocumentController

    var body: some View {
        if let hoverPoint = documentController.hoverPoint {
            Text("\(hoverPoint.x), \(hoverPoint.y)")
                .font(Font.body.monospacedDigit())
        }
    }
}

#Preview {
    EditorView(document: .constant(SpriteImageDocument(size: .defaultSize)))
}

