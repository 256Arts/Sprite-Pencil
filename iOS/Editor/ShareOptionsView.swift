//
//  ExportView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-04-29.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct ShareOptionsView: View {
    
    @State var formatIndex = 0
    @State var backgroundIndex = 0
    @State var scale = 1
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Format:")
                    Picker("Format", selection: self.$formatIndex, content: {
                        Text("PNG").tag(0)
                        Text("JPG").tag(1)
                    }).pickerStyle(SegmentedPickerStyle())
                }
                if formatIndex == 1 {
                    HStack {
                        Text("Background:")
                        Picker("Background", selection: self.$backgroundIndex, content: {
                            Text("White").tag(0)
                            Text("Black").tag(1)
                        }).pickerStyle(SegmentedPickerStyle())
                    }
                }
                HStack {
                    Text("Scale:")
                    Spacer()
                    TextField("Scale", text: Binding(get: {
                        "\(self.scale)x"
                    }, set: { (newValue) in
                        self.scale = min(max(1, Int(newValue.replacingOccurrences(of: "x", with: "")) ?? 1), 30)
                    }))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 64)
                }
            }
            Section {
                Button(action: {
                    let jpegBackgroundColor = self.backgroundIndex == 0 ? UIColor.white : UIColor.black
                    NotificationCenter.default.post(name: NSNotification.Name("showShareSheet"), object: nil, userInfo: [
                        "asPNG": self.formatIndex == 0,
                        "backgroundColor": (self.formatIndex == 0 ? nil : jpegBackgroundColor) as Any,
                        "scale": CGFloat(self.scale)
                    ])
                }, label: { Text("Share").bold().frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .center) })
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground)) // For iPhone, but doesn't work :(
        .listStyle(InsetGroupedListStyle())
        .frame(maxWidth: 414, alignment: .center)
    }
}

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ShareOptionsView()
    }
}
