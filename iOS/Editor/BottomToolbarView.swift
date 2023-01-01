//
//  ToolToolbarView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-05-16.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI
import SpritePencilKit
import Combine

struct BottomToolbarView: View {
    
    static let minWidthNeededForSingleRowBar: CGFloat = 600.0
    static let minWidthNeededForHoverPointLabel: CGFloat = 850.0
    static var subscription: AnyCancellable?
    
    #if targetEnvironment(macCatalyst)
    let isCatalyst = true
    
    // macOS 12.0 Bug workaround (Bug: Symbols do not respond to font/scale changes, they stay small.)
    static func largeSymbol(systemName: String) -> UIImage? {
        guard let symbol = UIImage(systemName: systemName)?.applyingSymbolConfiguration(.init(pointSize: 19)) else { return nil }
        
        let format = UIGraphicsImageRendererFormat()
        format.preferredRange = .standard
        
        return UIGraphicsImageRenderer(size: symbol.size, format: format).image { _ in symbol.draw(at: .zero) }.withRenderingMode(.alwaysTemplate)
    }
    #else
    let isCatalyst = false
    #endif
    
    @ObservedObject var editorVC: EditorViewController
    
    let colorSubject = PassthroughSubject<ColorComponents, Never>()
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width < BottomToolbarView.minWidthNeededForSingleRowBar { // Compact-Width Double-Row
                VStack(spacing: 0) {
                    ToolsView(editorVC: self.editorVC)
                        .frame(height: 44)
                    HStack(spacing: 16) {
                        if self.editorVC.hoverPoint != nil {
                            Text("\(self.editorVC.hoverPoint!.x), \(self.editorVC.hoverPoint!.y)")
                                .font(Font.body.monospacedDigit())
                        }
                        Spacer()
                        if self.editorVC.autoSplitViewController?.showDetail == true && self.editorVC.autoSplitViewController?.splitStack.axis == .vertical {
                            Button(action: {
                                self.editorVC.showPaletteChooser()
                            }, label: {
                                Image(systemName: "paintpalette")
                            })
                            .help("Choose Palette")
                        }
                        ColorPicker("Color", selection: Binding(get: {
                            let components = self.editorVC.canvasView.documentController.toolColorComponents
                            return Color(components: components)
                        }, set: { newValue in
                            setColor(newValue)
                        }))
                        .labelsHidden()
                        .frame(maxWidth: 32, maxHeight: 32)
                    }
                    .frame(height: 44)
                    .overlay {
                        if editorVC.currentBrushWidth != nil {
                            HStack {
                                LabeledStepper(min: 1, max: 10, value: Binding(get: {
                                    self.editorVC.currentBrushWidth ?? 1
                                }, set: { newValue in
                                    self.editorVC.currentBrushWidth = newValue
                                }))
                                DitherToggle(isOn: Binding(get: {
                                    editorVC.canvasView?.documentController?.checkeredDrawingMode ?? false
                                }, set: { newValue in
                                    editorVC.objectWillChange.send()
                                    editorVC.canvasView?.documentController?.checkeredDrawingMode = newValue
                                }))
                            }
                        }
                    }
                }
                .font(Font.system(size: 21))
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
            } else { // Large-Width Single-Row
                HStack(spacing: 16) {
                    if geometry.size.width < BottomToolbarView.minWidthNeededForHoverPointLabel && self.editorVC.currentBrushWidth != nil {
                        LabeledStepper(min: 1, max: 10, value: Binding(get: {
                            self.editorVC.currentBrushWidth!
                        }, set: { newValue in
                            self.editorVC.currentBrushWidth = newValue
                        }))
                    } else if self.editorVC.hoverPoint != nil {
                        Text("\(self.editorVC.hoverPoint!.x), \(self.editorVC.hoverPoint!.y)")
                            .font(Font.body.monospacedDigit())
                    }
                    Spacer()
                    if self.editorVC.currentBrushWidth != nil {
                        if BottomToolbarView.minWidthNeededForHoverPointLabel <= geometry.size.width {
                            LabeledStepper(min: 1, max: 10, value: Binding(get: {
                                self.editorVC.currentBrushWidth!
                            }, set: { newValue in
                                self.editorVC.currentBrushWidth = newValue
                            }))
                        }
                        DitherToggle(isOn: Binding(get: {
                            editorVC.canvasView?.documentController?.checkeredDrawingMode ?? false
                        }, set: { newValue in
                            editorVC.objectWillChange.send()
                            editorVC.canvasView?.documentController?.checkeredDrawingMode = newValue
                        }))
                    }
                    if self.editorVC.autoSplitViewController?.showDetail == true && self.editorVC.autoSplitViewController?.splitStack.axis == .vertical {
                        Button(action: {
                            self.editorVC.showPaletteChooser()
                        }, label: {
                            Image(systemName: "paintpalette")
                        })
                        .help("Choose Palette")
                    }
                    ColorPicker("Color", selection: Binding(get: {
                        let components = self.editorVC.canvasView.documentController.toolColorComponents
                        return Color(components: components)
                    }, set: { newValue in
                        self.setColor(newValue)
                    }))
                    .labelsHidden()
                    .frame(maxWidth: 32, maxHeight: 32)
                }
                .font(Font.system(size: 21))
                .frame(height: 44)
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
                .overlay(ToolsView(editorVC: self.editorVC))
            }
        }
        .onAppear {
            BottomToolbarView.subscription = colorSubject
                .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
                .sink { (components) in
                    self.editorVC.selectedColorDidChange(colorComponents: components)
                    self.editorVC.paletteCollectionVC.selectedColor = components
                    self.editorVC.paletteCollectionVC.collectionView.reloadData()
                }
        }
    }
    
    func setColor(_ color: Color) {
        let colorSpace: Color.RGBColorSpace = (color.cgColor?.colorSpace?.name == CGColorSpace.displayP3) ? .displayP3 : .sRGB
        let uiColor = UIColor(color)
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var opacity: CGFloat = 0.0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        
        // Clamp P3 colors to sRGB
        red = max(0.0, min(red, 1.0))
        green = max(0.0, min(green, 1.0))
        blue = max(0.0, min(blue, 1.0))
        
        let components = ColorComponents(colorSpace, red: UInt8(red*255), green: UInt8(green*255), blue: UInt8(blue*255), opacity: UInt8(opacity*255))
        colorSubject.send(components)
    }
    
}

struct ToolToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        BottomToolbarView(editorVC: EditorViewController())
    }
}
