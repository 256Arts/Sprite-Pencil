//
//  TemplatePickerView.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2021-02-25.
//  Copyright © 2021 256 Arts Developer. All rights reserved.
//

import SwiftUI
import SpritePencilKit

struct TemplatePickerView: View {
    
    #if targetEnvironment(macCatalyst)
    let isCatalyst = true
    #else
    let isCatalyst = false
    #endif
    
    let onComplete: (SpriteSize?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State var selectedSize = SpriteSize.defaultSize
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Square")
                        .font(.headline)
                    HStack {
                        ForEach(SpriteSize.squareSizes) { (size) in
                            Text("\(size.width)x\(size.height)")
                                .frame(width: 60, height: 60)
                                .background(size == selectedSize ? Color.yellowAccent : Color(UIColor.tertiarySystemFill))
                                .foregroundStyle(size == selectedSize ? Color.black : .primary)
                                .font(Font.system(size: 17))
                                .onTapGesture {
                                    selectedSize = size
                                }
                        }
                    }
                    Text("16:9")
                        .font(.headline)
                        .padding(.top, 8)
                    HStack {
                        ForEach(SpriteSize.widescreenSizes) { (size) in
                            Text("\(size.width)x\(size.height)")
                                .frame(width: 112, height: 63)
                                .background(size == selectedSize ? Color.yellowAccent : Color(UIColor.tertiarySystemFill))
                                .foregroundStyle(size == selectedSize ? Color.black : .primary)
                                .font(Font.system(size: 17))
                                .onTapGesture {
                                    selectedSize = size
                                }
                        }
                    }
                    Text("Templates")
                        .font(.headline)
                        .padding(.top, 8)
                    Link(destination: URL(string: "https://apps.apple.com/app/sprite-catalog/id1560692872")!, label: {
                        Label("Sprite Catalog", systemImage: "arrow.up.forward.app")
                    })
                }
                .padding()
                Spacer()
                TemplatePickerBottomBar(selectedSize: $selectedSize)
            }
            .navigationTitle("New Sprite")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(isCatalyst)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete(nil)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onComplete(selectedSize)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TemplatePickerView(onComplete: { _ in })
}
