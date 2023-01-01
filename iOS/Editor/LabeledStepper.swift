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
    
    @Binding var value: Int
    
    var body: some View {
        #if targetEnvironment(macCatalyst)
        HStack(spacing: 0) {
            Text(String(value))
                .font(.body)
                .frame(width: 16)
                .accessibilityHidden(true)
            Stepper("Brush Size", value: $value, in: min...max)
        }
        #else
        HStack {
            Button {
                self.value -= 1
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(StepperButtonStyle())
            .disabled(self.value <= min)
            
            Button {
                self.value += 1
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(StepperButtonStyle())
            .disabled(max <= self.value)
        }
        .background(Color(UIColor.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            Text(String(self.value))
        }
        .accentColor(Color(UIColor.label))
        #endif
    }
}

#if !targetEnvironment(macCatalyst)
private struct StepperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(minWidth: 32, minHeight: 32)
            .contentShape(Rectangle())
    }
}
#endif

struct LabeledStepper_Previews: PreviewProvider {
    static var previews: some View {
        LabeledStepper(min: 1, max: 10, value: .constant(5))
    }
}
