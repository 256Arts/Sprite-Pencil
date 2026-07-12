//
//  DitherToggle.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2022-12-31.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct DitherToggle: View {
    
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Image(systemName: "checkerboard.rectangle")
            #if targetEnvironment(macCatalyst)
                .imageScale(.large)
            #endif
        }
        .toggleStyle(.button)
        .help("Dithering Mode")
        .keyboardShortcut("D")
    }
}

#Preview {
    DitherToggle(isOn: .constant(true))
}
