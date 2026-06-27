//
//  RoundBrushToggle.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2026-06-25.
//  Copyright © 2026 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct RoundBrushToggle: View {

    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            #if targetEnvironment(macCatalyst)
            Image(uiImage: BottomToolbarView.largeSymbol(systemName: isOn ? "circle.fill" : "square.fill")!)
            #else
            Image(systemName: isOn ? "circle.fill" : "square.fill")
            #endif
        }
        .help("Round Brush")
    }
}

#Preview {
    RoundBrushToggle(isOn: .constant(true))
}
