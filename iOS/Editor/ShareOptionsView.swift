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

    @State var scale = 1
    
    var body: some View {
        // BUG: Cannot present `UIActivityViewController` on VC which is already presenting
        /*
        Picker("Scale", selection: $scale) {
            ForEach([1, 2, 4, 8, 16], id: \.self) { scale in
                Text("\(scale)x").tag(scale)
            }
        }
        .pickerStyle(.palette)
        .menuActionDismissBehavior(.disabled)
        
        ShareLink(
            item: Image(
                uiImage: documentController.export(scale: CGFloat(scale), backgroundColor: nil) ?? UIImage()
            ),
            preview: SharePreview(
                "My Sprite Pencil Art",
                image: Image(
                    uiImage: documentController.export(scale: CGFloat(scale), backgroundColor: nil) ?? UIImage()
                )
            )
        )
        .buttonStyle(.borderedProminent)
        
        Divider()
         */
        
        Button("Set Widget Sprite", systemImage: "square") {
            if let uiImage = documentController.export(scale: CGFloat(scale), backgroundColor: nil),
               let data = uiImage.pngData(),
               let defaults = UserDefaults(suiteName: SpritePencilApp.spritePencilAppGroupID) {
                defaults.set(data, forKey: "sprite")
                if let hex = UserDefaults.standard.string(forKey: UserDefaults.Key.currentColor) {
                    defaults.set(hex, forKey: "backgroundColor")
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

#Preview {
    ShareOptionsView(documentController: DocumentController())
}
