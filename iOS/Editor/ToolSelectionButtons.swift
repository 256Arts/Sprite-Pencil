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

    @Binding var selectedTool: EditorTool

    var body: some View {
        HStack {
            ToolSelectionButtons(selectedTool: $selectedTool)
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

    @Binding var selectedTool: EditorTool

    var body: some View {
        ForEach(EditorTool.allCases) { tool in
            Toggle(isOn: Binding(get: {
                selectedTool == tool
            }, set: { isOn in
                if isOn { selectedTool = tool }
            })) {
                Label { Text(tool.title) } icon: { tool.icon }
            }
        }
    }
}

#Preview {
    ToolSelectionButtons(selectedTool: .constant(.pencil))
}
