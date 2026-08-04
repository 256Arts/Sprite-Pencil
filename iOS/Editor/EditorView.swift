import PhotosUI
import SpritePencilKit
import StoreKit
import SwiftUI
import UIKit

struct EditorView: View {

    let document: SpriteImageDocument

    @Environment(\.undoManager) private var undoManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dismiss) private var dismiss

    // Canvas configuration state (mirrors prior defaults/controls)
    @AppStorage(UserDefaults.Key.showPixelGrid) private var pixelGridEnabled: Bool = false
    @AppStorage(UserDefaults.Key.showTileGrid) private var tileGridEnabled: Bool = false
    @AppStorage(UserDefaults.Key.showTiledPreview) private var tiledPreviewEnabled: Bool = false
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
    @AppStorage(UserDefaults.Key.showPermanentEditWarning) private var showPermanentEditWarning: Bool = true
    @AppStorage(UserDefaults.Key.autosaveEnabled) private var autosaveEnabled: Bool = true

    // Palette controller bridged into SwiftUI Inspector
    @State private var paletteController = PaletteCollectionController()
    
    @State private var documentController = DocumentController()

    @State private var showingInspector = true
    @State private var inspectorDetent: PresentationDetent = .height(Self.inspectorPeekDetentHeight)
    @State private var pendingPalette: Palette?
    @State private var isExportPresented = false
    @State private var isSettingsPresented = false
    @State private var showingPaletteChooser = false
    @State private var isPermanentEditWarningPresented = false

    // Tracing reference shown behind the sprite's transparent pixels.
    // Session-only: not saved with the document.
    @State private var referenceImage: UIImage?
    @State private var referencePhotoItem: PhotosPickerItem?
    @State private var isReferencePickerPresented = false

    // Mirrors of `undoManager.canUndo/canRedo`, refreshed on the kit's
    // `.refreshUndo` events so the Undo/Redo buttons update deterministically
    // instead of riding incidental re-renders.
    @State private var canUndo = false
    @State private var canRedo = false

    // Manual-save state, used only while `autosaveEnabled` is off.
    //
    // SwiftUI treats a document as having unsaved changes purely on the
    // strength of undo actions registered with the *document's* undo manager,
    // so the way to stop it autosaving is to hand the drawing engine a
    // different manager. This one is ours: undo/redo keep working exactly as
    // before, but nothing reaches the file until the person says so.
    // `DocumentController.undoManager` is `weak`, so this must be held here.
    @State private var manualUndoManager = UndoManager()
    @State private var hasUnsavedChanges = false
    @State private var isCloseConfirmationPresented = false
    @State private var saveErrorMessage: String?
    @State private var isShakeUndoPresented = false

    /// The person has edits that only exist in memory, so closing the document
    /// has to ask first.
    private var needsSaveConfirmation: Bool {
        !autosaveEnabled && hasUnsavedChanges
    }

    init(document: SpriteImageDocument) {
        self.document = document

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
            tiledPreviewEnabled: tiledPreviewEnabled,
            checkerboardColor1: canvasBackground.checkerColors.base,
            checkerboardColor2: canvasBackground.checkerColors.alternate,
            tileGridColor: .systemGray3,
            pixelGridColor: .systemGray3,
            twoFingerUndoEnabled: twoFingerUndoEnabled,
            applePencilCanEyedrop: true,
            nonDrawingFingerAction: nonDrawingFingerAction,
            shouldFillPaths: false,
            referenceImage: referenceImage,
            onEvent: { event in
                switch event {
                case .drawingDidChange, .didEndUsingTool:
                    // Hand the live canvas image to the document (cheap bitmap
                    // copy). SwiftUI autosaves off the kit's undo actions and
                    // PNG-encodes this off the main actor in the writer — no more
                    // hand-rolled on-main encode coalescing.
                    document.currentImage = documentController.context?.makeImage()
                    if !autosaveEnabled {
                        hasUnsavedChanges = true
                    }
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
                    refreshUndoState()
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
            // Deliberately a look-alike for the document's own close button,
            // which is hidden below while edits are pending: same chevron, same
            // slot, so the editor looks unchanged. The only difference is that
            // this one asks before throwing the drawing away.
            if needsSaveConfirmation {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "chevron.backward") {
                        isCloseConfirmationPresented = true
                    }
                    .labelStyle(.iconOnly)
                }
            }

            // Keep Undo away from the document's close button (also leading), so
            // reaching for Undo doesn't accidentally exit the document.
            ToolbarSpacer(.fixed, placement: .topBarLeading)
            ToolbarItemGroup(placement: .topBarLeading) {
                // The shortcuts are only claimed while Autosave is off. In that
                // mode the drawing's history lives in a private undo manager, so
                // UIKit's built-in ⌘Z — which drives the responder chain's
                // manager — has nothing to undo; the rest of the time the system
                // handles these keys and we stay out of its way.
                Button("Undo", systemImage: "arrow.uturn.left") { documentController.undo() }
                    .disabled(!canUndo)
                    .keyboardShortcut(autosaveEnabled ? nil : KeyboardShortcut("z", modifiers: .command))
                Button("Redo", systemImage: "arrow.uturn.right") { documentController.redo() }
                    .disabled(!canRedo)
                    .keyboardShortcut(autosaveEnabled ? nil : KeyboardShortcut("z", modifiers: [.command, .shift]))
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
                    // Surrounds the canvas with repeats of the sprite, for
                    // checking that a tilemap tile meets its own edges.
                    Toggle("Tiled Preview", systemImage: "square.grid.3x3", isOn: $tiledPreviewEnabled)
                    Divider()
                    // The canvas redraws its symmetry guides itself when these change.
                    Toggle("Vertical Symmetry", systemImage: "square.split.2x1", isOn: $documentController.verticalSymmetry)
                    Toggle("Horizontal Symmetry", systemImage: "square.split.1x2", isOn: $documentController.horizontalSymmetry)
                    Divider()
                    Button("Import Reference Image", systemImage: "photo.badge.plus") {
                        isReferencePickerPresented = true
                    }
                    if referenceImage != nil {
                        Button("Remove Reference Image", systemImage: "trash") {
                            referenceImage = nil
                        }
                    }
                }
            }
            // These editing actions are the first to move into the overflow menu
            // when the bar is tight (compact width), keeping Undo/Redo, Share, and
            // Settings visible.
            .visibilityPriority(.low)

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
        // Replaced by the Close button above, so unsaved edits can't be
        // discarded by a stray tap. Only ever hidden while a save is pending.
        .navigationBarBackButtonHidden(needsSaveConfirmation)
        .background {
            #if !targetEnvironment(macCatalyst) && !os(visionOS)
            // Only while Autosave is off, for the same reason as the ⌘Z
            // shortcuts above: UIKit's own shake-to-undo reads the responder
            // chain's undo manager, which is empty in that mode.
            if !autosaveEnabled {
                ShakeDetector {
                    guard canUndo || canRedo else { return }
                    isShakeUndoPresented = true
                }
                .accessibilityHidden(true)
            }
            #endif
        }
        // Mirrors the system's shake-to-undo alert: a shake is easy to trigger
        // by accident, so it asks rather than acting.
        .alert("Undo Drawing?", isPresented: $isShakeUndoPresented) {
            Button("Undo") { documentController.undo() }
                .disabled(!canUndo)
            if canRedo {
                Button("Redo") { documentController.redo() }
            }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog("Save Changes?", isPresented: $isCloseConfirmationPresented, titleVisibility: .visible) {
            Button("Save") {
                Task {
                    await save()
                    if saveErrorMessage == nil {
                        dismiss()
                    }
                }
            }
            Button("Discard Changes", role: .destructive) {
                hasUnsavedChanges = false
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Autosave is off, so your edits haven't been written to the file yet.")
        }
        .alert("Unable to Save", isPresented: Binding(get: { saveErrorMessage != nil }, set: { if !$0 { saveErrorMessage = nil } })) {
            Button("OK", role: .close) { }
        } message: {
            Text(saveErrorMessage ?? "")
        }
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
        .photosPicker(isPresented: $isReferencePickerPresented, selection: $referencePhotoItem, matching: .images)
        .onChange(of: referencePhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    referenceImage = UIImage(data: data)
                }
                referencePhotoItem = nil
            }
        }
        .sheet(isPresented: $showingPaletteChooser) {
            NavigationStack {
                PalettePickerView(selectedPaletteName: paletteController.palette?.name ?? "") { palette in
                    paletteController.palette = palette
                }
            }
        }
        .onAppear {
            applyUndoManager()
            // One-time heads-up, restored from the pre-SwiftUI app. Only for
            // documents opened from disk, with copy updated for the autosaving
            // document model.
            if !document.isNewDocument, showPermanentEditWarning {
                showPermanentEditWarning = false
                isPermanentEditWarningPresented = true
            }
        }
        .alert("Permanent Edits", isPresented: $isPermanentEditWarningPresented) {
            Button("OK", role: .close) { }
        } message: {
            Text("While drawing you can undo edits. Edits are saved to the file automatically. To be asked before edits are written, turn off Autosave in Settings.")
        }
        .onChange(of: undoManager) { _, _ in
            // The environment's manager can be nil on first render or replaced
            // under DocumentGroup; re-wire the controller whenever it changes.
            applyUndoManager()
        }
        .onChange(of: autosaveEnabled) { _, isEnabled in
            // Turning autosaving back on has to flush whatever was held back,
            // otherwise those edits would sit in memory with no Save button
            // left to write them.
            if isEnabled, hasUnsavedChanges {
                Task { await save() }
            }
            applyUndoManager()
        }
        .onDisappear {
            documentsClosedCount += 1
            if [5, 20, 50, 100].contains(documentsClosedCount) {
                requestReview()
            }
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

    // MARK: - Saving

    /// Points the drawing engine at the undo manager that matches the current
    /// autosave setting: the document's (SwiftUI sees the edits and writes
    /// them) or our private one (SwiftUI sees nothing, the file is untouched).
    ///
    /// Switching modes mid-document starts a fresh undo stack, since the two
    /// managers hold separate histories.
    private func applyUndoManager() {
        documentController.undoManager = autosaveEnabled ? undoManager : manualUndoManager
        refreshUndoState()
    }

    private func refreshUndoState() {
        canUndo = documentController.undoManager?.canUndo ?? false
        canRedo = documentController.undoManager?.canRedo ?? false
    }

    /// Writes the canvas to the file and clears the pending-changes flag.
    /// Surfaces failures rather than swallowing them — with autosaving off
    /// this is the only write, so a silent failure would lose the drawing.
    private func save() async {
        guard let image = documentController.context?.makeImage() else { return }
        do {
            try await document.saveNow(image: image)
            hasUnsavedChanges = false
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private var currentPalette: Palette {
        PaletteStore.shared.palette(named: colorPaletteName) ?? PaletteStore.shared.defaultPalette
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
    EditorView(document: SpriteImageDocument(size: .defaultSize))
}

