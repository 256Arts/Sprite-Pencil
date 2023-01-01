//
//  ToolsView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-09-13.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct ToolsView: View {
    
    static var selectedForeground: Color {
        #if targetEnvironment(macCatalyst)
        Color(uiColor: .systemBackground)
        #else
        Color("Brand")
        #endif
    }
    static var selectedBackground: Color {
        #if targetEnvironment(macCatalyst)
        Color(uiColor: .systemGray)
        #else
        Color("Selected Background")
        #endif
    }
    static let unselectedForeground = Color(uiColor: .systemGray)
    
    @ObservedObject var editorVC: EditorViewController
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .foregroundColor(Self.selectedBackground)
                .frame(width: 36, height: 36, alignment: .center)
                .offset(x: CGFloat(self.editorVC.selectedToolIndex-3)*49.75 - 0.6666, y: 0)
            HStack(spacing: 26) {
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        self.editorVC.selectedToolIndex = 0
                    }
                    self.editorVC.canvasView.tool = self.editorVC.canvasView.documentController.pencilTool
                }, label: { Image("Brush") })
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(.borderless)
                    #endif
                    .accentColor(self.editorVC.selectedToolIndex == 0 ? Self.selectedForeground : Self.unselectedForeground)
                    .help("Brush")
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        self.editorVC.selectedToolIndex = 1
                    }
                    self.editorVC.canvasView.tool = self.editorVC.canvasView.documentController.eraserTool
                }, label: { Image("Eraser") })
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(.borderless)
                    #endif
                    .accentColor(self.editorVC.selectedToolIndex == 1 ? Self.selectedForeground : Self.unselectedForeground)
                    .help("Eraser")
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        self.editorVC.selectedToolIndex = 2
                    }
                    self.editorVC.canvasView.tool = self.editorVC.canvasView.documentController.fillTool
                }, label: { Image("Bucket") })
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(.borderless)
                    #endif
                    .accentColor(self.editorVC.selectedToolIndex == 2 ? Self.selectedForeground : Self.unselectedForeground)
                    .help("Fill")
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        self.editorVC.selectedToolIndex = 3
                    }
                    self.editorVC.canvasView.tool = self.editorVC.canvasView.documentController.moveTool
                }, label: {
                    #if targetEnvironment(macCatalyst)
                    Image(uiImage: BottomToolbarView.largeSymbol(systemName: "arrow.up.and.down.and.arrow.left.and.right")!).frame(width: 24)
                    #else
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right").frame(width: 24)
                    #endif
                })
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(.borderless)
                    #endif
                    .accentColor(self.editorVC.selectedToolIndex == 3 ? Self.selectedForeground : Self.unselectedForeground)
                    .help("Move")
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        self.editorVC.selectedToolIndex = 4
                    }
                    self.editorVC.canvasView.tool = self.editorVC.canvasView.documentController.highlightTool
                }, label: { Image("Highlight") })
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(.borderless)
                    #endif
                    .accentColor(self.editorVC.selectedToolIndex == 4 ? Self.selectedForeground : Self.unselectedForeground)
                    .help("Highlight")
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        self.editorVC.selectedToolIndex = 5
                    }
                    self.editorVC.canvasView.tool = self.editorVC.canvasView.documentController.shadowTool
                }, label: { Image("Shadow") })
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(.borderless)
                    #endif
                    .accentColor(self.editorVC.selectedToolIndex == 5 ? Self.selectedForeground : Self.unselectedForeground)
                    .help("Shadow")
                Button(action: {
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        self.editorVC.selectedToolIndex = 6
                    }
                    self.editorVC.canvasView.tool = self.editorVC.canvasView.documentController.eyedroperTool
                }, label: {
                    #if targetEnvironment(macCatalyst)
                    Image(uiImage: BottomToolbarView.largeSymbol(systemName: "eyedropper")!).frame(width: 24)
                    #else
                    Image(systemName: "eyedropper").frame(width: 24)
                    #endif
                })
                    #if targetEnvironment(macCatalyst)
                    .buttonStyle(.borderless)
                    #endif
                    .accentColor(self.editorVC.selectedToolIndex == 6 ? Self.selectedForeground : Self.unselectedForeground)
                    .help("Eyedropper")
            }
        }
        .font(Font.system(size: 19))
    }
}

struct ToolsView_Previews: PreviewProvider {
    static var previews: some View {
        ToolsView(editorVC: EditorViewController())
    }
}
