//
//  LabeledStepper.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-09-14.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct LabeledStepper: View {
    
    let min: Int
    let max: Int
    #if targetEnvironment(macCatalyst)
    let cornerRadius: CGFloat = 6.0
    #else
    let cornerRadius: CGFloat = 10.0
    #endif
    
    @Binding var value: Int
    
    var body: some View {
        HStack {
            Button(action: {
                self.value -= 1
            }, label: {
                Image(systemName: "minus")
            })
                .buttonStyle(StepperButtonStyle())
                .disabled(self.value <= min)
            Button(action: {
                self.value += 1
            }, label: {
                Image(systemName: "plus")
            })
                .buttonStyle(StepperButtonStyle())
                .disabled(max <= self.value)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(Text(String(self.value)))
        .cornerRadius(cornerRadius)
        .accentColor(Color(UIColor.label))
    }
}

private struct StepperButtonStyle: ButtonStyle {
    #if targetEnvironment(macCatalyst)
    let paddingInsets = EdgeInsets()
    #else
    let paddingInsets = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    #endif
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(paddingInsets)
            .frame(minWidth: 32, minHeight: 32)
    }
}

struct LabeledStepper_Previews: PreviewProvider {
    static var previews: some View {
        LabeledStepper(min: 1, max: 10, value: .constant(5))
    }
}
