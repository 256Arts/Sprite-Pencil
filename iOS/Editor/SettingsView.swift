//
//  SettingsView.swift
//  Sprite Pencil
//
//  Created by 256 Arts Developer on 2023-01-02.
//  Copyright © 2023 256 Arts Developer. All rights reserved.
//

import SwiftUI

enum AppID: Int {
    case spritePencil = 1437835952
    case spriteCatalog = 1560692872
    case spriteFonts = 1554027877
}

struct SettingsView: View {
    
    let editorVC: EditorViewController
    
    @AppStorage(UserDefaults.Key.autosave) var autosave = true
    @AppStorage(UserDefaults.Key.canvasBackgroundColor) var canvasBackgroundColor = "default"
    @AppStorage(UserDefaults.Key.fingerAction) var fingerAction = "ignore"
    @AppStorage(UserDefaults.Key.twoFingerUndoEnabled) var twoFingerUndoEnabled = true
    @AppStorage(UserDefaults.Key.showColorNotifications) var showColorNotifications = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                Toggle("Autosave", isOn: $autosave)
                Picker("Canvas Background", selection: $canvasBackgroundColor) {
                    Text("Default")
                        .tag("default")
                    Text("White")
                        .tag("white")
                    Text("Pink")
                        .tag("pink")
                    Text("Green")
                        .tag("green")
                }
                Picker("Finger Action", selection: $fingerAction) {
                    Text("Move")
                        .tag("move")
                    Text("Eyedrop")
                        .tag("eyedrop")
                    Text("Ignore")
                        .tag("ignore")
                }
                Toggle("2 Finger Undo", isOn: $twoFingerUndoEnabled)
                Toggle("Show HEX Notifications", isOn: $showColorNotifications)
            }
            Section {
                NavigationLink("Help") {
                    HelpView()
                }
            }
            Section(header: Text("More".uppercased())) {
                NavigationLink("Support Indie Development") {
                    GiftAppHelpView(editorVC: editorVC)
                }
                Button {
                    editorVC.showAppStorePage()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Try Sprite Catalog")
                            Text("2000+ Pixel Art Assets")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    } icon: {
                        Image(systemName: "arrow.down.app")
                            .imageScale(.large)
                    }
                }
                .foregroundColor(Color("Brand"))
                Button {
                    editorVC.showAppStorePage2()
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Try Sprite Fonts")
                            Text("Install Pixel Fonts")
                                .font(.subheadline)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    } icon: {
                        Image(systemName: "arrow.down.app")
                            .imageScale(.large)
                    }
                }
                .foregroundColor(Color("Brand"))
                Link(destination: URL(string: "https://www.jaydenirwin.com/")!) {
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
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    editorVC.refreshCanvasBackground()
                    dismiss()
                }
            }
        }
        .imageScale(.large)
        .onAppear {
            editorVC.loadAppStorePage(id: .spriteCatalog)
            editorVC.loadAppStorePage2(id: .spriteFonts)
        }
    }
}

struct GiftAppHelpView: View {
    
    let editorVC: EditorViewController
    
    var body: some View {
        List {
            HStack {
                Image(systemName: "1.circle.fill")
                Button("View App Page", action: {
                    editorVC.showAppStorePage()
                })
                .foregroundColor(Color("Brand"))
            }
            HStack {
                Image(systemName: "2.circle.fill")
                Text("Tap \(Image(systemName: "square.and.arrow.up")).")
                    .imageScale(.medium)
            }
            HStack {
                Image(systemName: "3.circle.fill")
                Text("Tap \"Gift App…\".")
            }
            HStack {
                Image(systemName: "4.circle.fill")
                Text("Send your gift to a friend.")
            }
        }
        .navigationTitle("Gift The App")
        .onAppear() {
            editorVC.loadAppStorePage(id: .spritePencil)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(editorVC: EditorViewController())
    }
}
