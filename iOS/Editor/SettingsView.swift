//
//  SettingsView.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2023-01-02.
//  Copyright © 2023 256 Arts Developer. All rights reserved.
//

import SpritePencilKit
import SwiftUI

enum AppID: Int {
    case spritePencil = 1437835952
    case spriteCatalog = 1560692872
}

struct SettingsView: View {
    
    @AppStorage(UserDefaults.Key.canvasBackgroundColor) var canvasBackgroundColor: CanvasBackground = .default
    @AppStorage(UserDefaults.Key.fingerAction) var fingerAction: CanvasUIView.FingerAction = .ignore
    @AppStorage(UserDefaults.Key.twoFingerUndoEnabled) var twoFingerUndoEnabled = true
    @AppStorage(UserDefaults.Key.showColorNotifications) var showColorNotifications = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityAssistiveAccessEnabled) private var isAssistiveAccessEnabled
    
    var body: some View {
        List {
            Section {
                Picker("Canvas Background", selection: $canvasBackgroundColor) {
                    ForEach(CanvasBackground.allCases) { background in
                        Text(background.displayName)
                            .tag(background)
                    }
                }
                Picker("Finger Action", selection: $fingerAction) {
                    ForEach(CanvasUIView.FingerAction.userSelectableCases, id: \.self) { action in
                        Text(action.displayName)
                            .tag(action)
                    }
                }
                Toggle("2 Finger Undo", isOn: $twoFingerUndoEnabled)
                Toggle("Show HEX Notifications", isOn: $showColorNotifications)
            }
            
            Section {
                NavigationLink("Help") {
                    HelpView()
                }
            }
            
            #if !os(visionOS)
            if !isAssistiveAccessEnabled {
                Section("More") {
//                    Button {
//                        editorVC.showAppStorePage()
//                    } label: {
//                        Label {
//                            VStack(alignment: .leading) {
//                                Text("Try Sprite Catalog")
//                                Text("3000+ Pixel Art Assets")
//                                    .font(.subheadline)
//                                    .foregroundColor(Color(UIColor.secondaryLabel))
//                            }
//                        } icon: {
//                            Image(systemName: "arrow.down.app")
//                                .imageScale(.large)
//                        }
//                    }
//                    .foregroundColor(.yellowAccent)
                
                    Link(destination: URL(string: "https://www.256arts.com/")!) {
                        Label("Developer Website", systemImage: "safari")
                    }
                    Link(destination: URL(string: "https://www.256arts.com/joincommunity/")!) {
                        Label("Join Community", systemImage: "bubble.left.and.bubble.right")
                    }
                    Link(destination: URL(string: "https://github.com/256Arts/Sprite-Pencil")!) {
                        Label("Contribute on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            #endif
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", systemImage: "checkmark") {
//                    editorVC.refreshCanvasBackground()
                    dismiss()
                }
            }
        }
        .imageScale(.large)
        #if !os(visionOS)
        .onAppear {
//            editorVC.loadAppStorePage(id: .spriteCatalog)
        }
        #endif
    }
}

#Preview {
    SettingsView()
}
