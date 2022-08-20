//
//  BottomSheetView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-05-03.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct BottomSheetView: View {
    
    @State var yOffset: CGFloat = 300.0
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    NotificationCenter.default.post(name: NSNotification.Name("dismissShareOptions"), object: nil)
                }
            ShareOptionsView()
                .frame(height: 225)
                .cornerRadius(20)
        }
        .padding()
        .offset(x: 0.0, y: self.yOffset)
        .onAppear() {
            withAnimation(Animation.easeOut(duration: 0.1)) {
                self.yOffset = 0.0
            }
        }
    }
}

struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetView()
    }
}
