//
//  AddPaletteView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-05-19.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI
import SpritePencilKit

struct AddPaletteView: View {
    
    static let dismissNotificationName = Notification.Name("dismissAddPalette")
    
    @State var palette: Palette
    @State var fromLospec: Bool
    
    var paletteImage: UIImage?
    var completionHandler: ((Bool) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Image(decorative: "Palette Colored")
                    Text("Add Palette")
                        .font(Font.system(size: 32, weight: .bold, design: .default))
                    if self.fromLospec {
                        Text("from lospec.com")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name:")
                            .font(.headline)
                        TextField("Name", text: $palette.name)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(6)
                    }
                    Spacer()
                    Button(action: {
                        Palette.addPalette(self.palette, paletteImage: self.paletteImage)
                        self.completionHandler?(true)
                        NotificationCenter.default.post(name: AddPaletteView.dismissNotificationName, object: nil)
                    }, label: {
                        Text("Add Palette")
                            .frame(width: 300)
                    })
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
                    .frame(width: 300)
                    .padding(.vertical, 64)
                    .navigationBarTitle("", displayMode: .inline)
                    .navigationBarItems(leading: Button(action: {
                        self.completionHandler?(false)
                        NotificationCenter.default.post(name: AddPaletteView.dismissNotificationName, object: nil)
                    }, label: { Text("Cancel") }))
            }
        }
    }
}

struct AddPaletteView_Previews: PreviewProvider {
    static var previews: some View {
        AddPaletteView(palette: Palette(name: "My Palette", specialCase: nil, colors: [], defaultGroupLength: 1), fromLospec: true)
    }
}
