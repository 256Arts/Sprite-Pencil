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
                        .foregroundStyle(.primary)
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
                        .foregroundStyle(.primary)
                    Text("px")
                }
            }
        }
        .padding(.bottom, 12)
        .background(Color(UIColor.tertiarySystemFill).opacity(0.4))
        .foregroundStyle(.secondary)
    }
}

#Preview {
    TemplatePickerBottomBar(selectedSize: .constant(SpriteSize(width: 16, height: 16)))
}
