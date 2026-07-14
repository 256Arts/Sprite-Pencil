import SpritePencilKit
import SwiftUI

struct MessagesView: View {
    
    init(insertFile: @escaping (URL) -> Void) {
        let documentController = DocumentController()
        documentController.palette = Palette.sp16
        _documentController = State(initialValue: documentController)

        let paletteController = PaletteCollectionController()
        paletteController.messagesAppMode = true
        paletteController.palette = Palette.sp16
        _paletteController = State(initialValue: paletteController)

        self.insertFile = insertFile
    }

    // @State so a re-init of the struct (any parent update) can't silently
    // replace the controllers and reset the canvas mid-drawing.
    @State private var documentController: DocumentController
    @State private var paletteController: PaletteCollectionController
    let insertFile: (URL) -> Void

    var body: some View {
        VStack {
            HStack {
                ZoomableCanvasView(
                    documentController: documentController,
                    zoomEnabled: false,
                    shouldRecognizeGesturesSimultaneously: false,
                    configure: { _ in
                        // The kit reacts to `loadContext` on its own
                        // (checkerboard, grid, zoom to fit — including refits
                        // on any later size change).
                        if documentController.context == nil, let context = CGContext.spriteDrawingContext(width: 16, height: 16) {
                            documentController.loadContext(context)
                        }
                    }
                )
                // BUG: Launch once from Xcode, then from iMessage itself, and the canvas will layout like expanded view even though it's in compact view
                // Workaround: Hardcode height
                .frame(height: 220)
                
                VStack {
                    Button("Insert", systemImage: "arrow.up", role: .confirm) {
                        guard let image = documentController.export(scale: 10), let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
                        let fileURL = url.appendingPathComponent("TempSticker.png")
                        do {
                            try image.pngData()?.write(to: fileURL)
                            insertFile(fileURL)
                        } catch {
                            print(error)
                        }
                    }
                    .bold()
                    .foregroundStyle(.black)
                    .buttonStyle(.glassProminent)
                    
                    Button("Clear", systemImage: "trash", role: .destructive) {
                        documentController.context.clear()
                        documentController.refresh()
                    }
                    .buttonStyle(.glass)
                }
                .controlSize(.extraLarge)
                .labelStyle(.iconOnly)
            }
            .scenePadding(.horizontal)
            
            PaletteCollectionView(
                controller: paletteController,
                selectedColor: Binding(get: {
                    self.documentController.toolColorComponents
                }, set: { newValue in
                    self.documentController.toolColorComponents = newValue
                    if !(self.documentController.tool is FillTool) {
                        self.documentController.tool = self.documentController.pencilTool
                    }
                })
            )
            .frame(height: 100)
        }
    }
}

#Preview {
    MessagesView(insertFile: { _ in })
}
