//
//  LabeledStepper.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2020-09-14.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
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
                .frame(width: 18, alignment: .leading)
                .accessibilityHidden(true)
            Stepper("Brush Size", value: $value, in: min...max)
                .labelsHidden()
        }
        #else
        HStack {
            Button {
                self.value -= 1
            } label: {
                Image(systemName: "minus")
            }
            .disabled(self.value <= min)
            
            Button {
                self.value += 1
            } label: {
                Image(systemName: "plus")
            }
            .disabled(max <= self.value)
        }
        .buttonStyle(StepperButtonStyle())
        .glassEffect(.regular)
        .overlay {
            Text(String(self.value))
                .allowsHitTesting(false)
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

#Preview {
    LabeledStepper(min: 1, max: 10, value: .constant(5))
}
