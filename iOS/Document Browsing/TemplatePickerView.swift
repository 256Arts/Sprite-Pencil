//
//  TemplatePickerView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2021-02-25.
//  Copyright © 2021 Jayden Irwin. All rights reserved.
//

import SwiftUI
import SpritePencilKit

struct TemplatePickerView: View {
    
    static let doneNotificationName = Notification.Name("templatePickerDone")
    
    #if targetEnvironment(macCatalyst)
    let isCatalyst = true
    #else
    let isCatalyst = false
    #endif
    
    @State var selectedSize = SpriteSize.defaultSize
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Square")
                        .font(.headline)
                    HStack {
                        ForEach(SpriteSize.squareSizes) { (size) in
                            Text("\(size.width)x\(size.height)")
                                .frame(width: 60, height: 60)
                                .background(size == selectedSize ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                                .foregroundColor(size == selectedSize ? Color(UIColor.systemBackground) : Color(UIColor.label))
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
                                .background(size == selectedSize ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                                .foregroundColor(size == selectedSize ? Color(UIColor.systemBackground) : Color(UIColor.label))
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
                        NotificationCenter.default.post(name: TemplatePickerView.doneNotificationName, object: nil)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        NotificationCenter.default.post(name: TemplatePickerView.doneNotificationName, object: selectedSize)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // For mac catalyst
    }
}

struct TemplatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        TemplatePickerView()
    }
}
