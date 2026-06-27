import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct SpriteImageDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png, .jpeg] }

    var data: Data

    init(size: SpriteSize) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.width, height: size.height), format: format)
        let png = renderer.pngData { _ in /* transparent */ }
        self.data = png
        
        UserDefaults.standard.incrementDocumentsCreatedCount()
    }

    init(configuration: ReadConfiguration) throws {
        if let fileData = configuration.file.regularFileContents {
            self.data = fileData
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func snapshot(contentType: UTType) throws -> Data { data }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
