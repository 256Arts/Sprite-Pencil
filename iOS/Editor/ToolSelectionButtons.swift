//
//  ToolSelectionButtons.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2020-09-13.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct ToolSelectionButtonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        if configuration.isOn {
            Button {
                configuration.isOn.toggle()
            } label: {
                configuration.label
            }
            .buttonStyle(.glassProminent)
            .tint(.yellowAccent)
            .foregroundStyle(.black)
            .frame(width: 48, height: 38)
        } else {
            Button {
                configuration.isOn.toggle()
            } label: {
                configuration.label
            }
            .buttonStyle(.borderless)
            .tint(.primary)
            .frame(width: 48, height: 38)
        }
    }
}

struct ToolSelectionBar: View {
    
    @Binding var selectedToolIndex: Int
    
    var body: some View {
        HStack {
            ToolSelectionButtons(selectedToolIndex: $selectedToolIndex)
                .toggleStyle(ToolSelectionButtonToggleStyle())
                .labelStyle(.iconOnly)
                .padding(.horizontal, -2)
        }
        .padding(2)
        .glassEffect()
    }
}

/// The buttons are separated into their own view in case we want to show them in a `.toolbar` in the future
struct ToolSelectionButtons: View {
    
    static var selectedForeground: Color {
        #if targetEnvironment(macCatalyst)
        Color(uiColor: .systemBackground)
        #else
        Color.yellowAccent
        #endif
    }
    static var selectedBackground: Color {
        #if targetEnvironment(macCatalyst)
        Color(uiColor: .systemGray)
        #else
        Color("Selected Background")
        #endif
    }
    static let unselectedForeground = Color(uiColor: .systemGray)
    
    @Binding var selectedToolIndex: Int
    
    var body: some View {
        Toggle("Brush", image: .brush, isOn: Binding(get: {
            selectedToolIndex == 0
        }, set: { newValue in
            if newValue {
                selectedToolIndex = 0
            }
        }))
        Toggle("Eraser", image: .eraser, isOn: Binding(get: {
            selectedToolIndex == 1
        }, set: { newValue in
            if newValue {
                selectedToolIndex = 1
            }
        }))
        Toggle("Bucket", image: .bucket, isOn: Binding(get: {
            selectedToolIndex == 2
        }, set: { newValue in
            if newValue {
                selectedToolIndex = 2
            }
        }))
        Toggle("Move", systemImage: "arrow.up.and.down.and.arrow.left.and.right", isOn: Binding(get: {
            selectedToolIndex == 3
        }, set: { newValue in
            if newValue {
                selectedToolIndex = 3
            }
        }))
        Toggle("Highlight", image: .highlight, isOn: Binding(get: {
            selectedToolIndex == 4
        }, set: { newValue in
            if newValue {
                selectedToolIndex = 4
            }
        }))
        Toggle("Shadow", image: .shadow, isOn: Binding(get: {
            selectedToolIndex == 5
        }, set: { newValue in
            if newValue {
                selectedToolIndex = 5
            }
        }))
        Toggle("Eyedropper", systemImage: "eyedropper", isOn: Binding(get: {
            selectedToolIndex == 6
        }, set: { newValue in
            if newValue {
                selectedToolIndex = 6
            }
        }))
    }
}

#Preview {
    ToolSelectionButtons(selectedToolIndex: .constant(0))
}
