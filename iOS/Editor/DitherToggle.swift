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
    
    var foregroundColor: Color {
        if isOn {
            return Color(UIColor.systemBackground)
        } else {
            #if targetEnvironment(macCatalyst)
            return Color(UIColor.systemGray)
            #else
            return .accentColor
            #endif
        }
    }
    var backgroundColor: Color {
        isOn ? .accentColor : .clear
    }
    
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            #if targetEnvironment(macCatalyst)
            Image(uiImage: BottomToolbarView.largeSymbol(systemName: "checkerboard.rectangle")!)
            #else
            Image(systemName: "checkerboard.rectangle")
            #endif
        }
        #if targetEnvironment(macCatalyst)
        .buttonStyle(.borderless)
        #endif
        .frame(width: 32, height: 32)
        .foregroundColor(foregroundColor)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 6))
        .help("Dithering Mode")
        .keyboardShortcut("D")
    }
}

struct DitherToggle_Previews: PreviewProvider {
    static var previews: some View {
        DitherToggle(isOn: .constant(true))
    }
}
