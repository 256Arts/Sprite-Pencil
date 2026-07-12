//
//  ExportView.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2020-04-29.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import SpritePencilKit
import WidgetKit

struct ShareOptionsView: View {

    var documentController: DocumentController

    // A `ShareLink` inside a `Menu` is a presentation within a presentation
    // and silently fails, so exporting opens a popover anchored to the menu's
    // toolbar button instead (see EditorView).
    @Binding var isExportPresented: Bool

    var body: some View {
        Button("Export Image", systemImage: "photo") {
            isExportPresented = true
        }

        Button("Set Widget Sprite", systemImage: "square") {
            if let uiImage = documentController.export(scale: 1, backgroundColor: nil),
               let data = uiImage.pngData(),
               let defaults = AppGroup.defaults {
                defaults.set(data, forKey: AppGroup.Key.sprite)
                if let hex = UserDefaults.standard.string(forKey: UserDefaults.Key.currentColor) {
                    defaults.set(hex, forKey: AppGroup.Key.backgroundColor)
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

struct ExportImageView: View {

    var documentController: DocumentController

    @State private var scale = 1

    private var exportedImage: Image {
        Image(uiImage: documentController.export(scale: CGFloat(scale), backgroundColor: nil) ?? UIImage())
    }

    var body: some View {
        VStack(spacing: 20) {
            Picker("Scale", selection: $scale) {
                ForEach([1, 2, 4, 8, 16], id: \.self) { scale in
                    Text("\(scale)x").tag(scale)
                }
            }
            .pickerStyle(.segmented)

            ShareLink(
                item: exportedImage,
                preview: SharePreview("My Sprite Pencil Art", image: exportedImage)
            )
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

#Preview {
    ShareOptionsView(documentController: DocumentController(), isExportPresented: .constant(false))
}
