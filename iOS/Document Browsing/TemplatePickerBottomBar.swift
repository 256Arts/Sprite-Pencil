//
//  TemplatePickerBottomBar.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2021-02-21.
//  Copyright © 2021 256 Arts Developer. All rights reserved.
//

import SwiftUI

struct TemplatePickerBottomBar: View {
    
    @Binding var selectedSize: SpriteSize
    
    var body: some View {
        VStack {
            Divider()
            VStack(alignment: .trailing) {
                HStack {
                    Text("Width:")
                    TextField("Width", text: Binding(get: {
                        String(selectedSize.width)
                    }, set: { (newValue) in
                        selectedSize.width = min(Int(newValue) ?? 1, SpriteSize.maxSize.width)
                    }))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .foregroundColor(Color(UIColor.label))
                    Text("px")
                }
                HStack {
                    Text("Height:")
                    TextField("Height", text: Binding(get: {
                        String(selectedSize.height)
                    }, set: { (newValue) in
                        selectedSize.height = min(Int(newValue) ?? 1, SpriteSize.maxSize.height)
                    }))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .foregroundColor(Color(UIColor.label))
                    Text("px")
                }
            }
            #if targetEnvironment(macCatalyst)
            Divider()
            HStack {
                Spacer()
                Button("Cancel") {
                    NotificationCenter.default.post(name: TemplatePickerView.doneNotificationName, object: nil)
                }
                Button("Create") {
                    NotificationCenter.default.post(name: TemplatePickerView.doneNotificationName, object: selectedSize)
                }
            }
            .padding(.horizontal)
            #endif
        }
        .padding(.bottom, 12)
        .background(Color(UIColor.tertiarySystemFill).opacity(0.4))
        .foregroundColor(Color(UIColor.secondaryLabel))
    }
}

#Preview {
    TemplatePickerBottomBar(selectedSize: .constant(SpriteSize(width: 16, height: 16)))
}
