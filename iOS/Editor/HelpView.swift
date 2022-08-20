//
//  HelpView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-10-25.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

enum AppID: Int {
    case spritePencil = 1437835952
    case spriteCatalog = 1560692872
    case spriteFonts = 1554027877
}

struct HelpView: View {
    
    let editorVC: EditorViewController
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NavigationLink("Tools", destination: ToolsHelpView())
                    NavigationLink("Create A Palette", destination: CreatePaletteHelpView())
                    NavigationLink("Use Widget", destination: WidgetHelpView())
                }
                Section(header: Text("More".uppercased())) {
                    NavigationLink("Support Indie Development", destination: GiftAppHelpView(editorVC: editorVC))
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
                    Link("Developer Website", destination: URL(string: "https://www.jaydenirwin.com/")!)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .imageScale(.large)
        .onAppear() {
            editorVC.loadAppStorePage(id: .spriteCatalog)
            editorVC.loadAppStorePage2(id: .spriteFonts)
        }
    }
}

struct ToolsHelpView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Image("Brush")
                    Text("Pencil")
                }
                HStack {
                    Image("Eraser")
                    Text("Eraser")
                }
                HStack {
                    Image("Bucket")
                    Text("Fill")
                }
                HStack {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    Text("Move")
                }
                HStack {
                    Image("Highlight")
                    Text("Highlight")
                }
                HStack {
                    Image("Shadow")
                    Text("Shadow")
                }
                HStack {
                    Image(systemName: "eyedropper")
                    Text("Eyedropper")
                }
            }
            Section {
                HStack {
                    Image(systemName: "checkerboard.rectangle")
                    VStack(alignment: .leading) {
                        Text("Dithering Mode")
                        Text("Helps drawing gradients by editing every other pixel.")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Tools")
    }
}

struct CreatePaletteHelpView: View {
    var body: some View {
        List {
            HStack {
                Image(systemName: "1.circle.fill")
                Text("Create a new sprite with a width equal to the number of colors you want, and a height of 1px.")
            }
            HStack {
                Image(systemName: "2.circle.fill")
                Text("Paint each pixel with a color for your palette.")
            }
            HStack {
                Image(systemName: "3.circle.fill")
                Text("Tap \(Image(systemName: "square.and.arrow.up")).")
                    .imageScale(.medium)
            }
            HStack {
                Image(systemName: "4.circle.fill")
                Text("Tap \"Share\". (PNG, 1x)")
            }
            HStack {
                Image(systemName: "5.circle.fill")
                Text("Tap \"Save as Palette\".")
            }
        }
        .navigationTitle("Create A Palette")
    }
}

struct WidgetHelpView: View {
    var body: some View {
        List {
            HStack {
                Image(systemName: "1.circle.fill")
                Text("Open the sprite.")
            }
            HStack {
                Image(systemName: "2.circle.fill")
                Text("Tap \(Image(systemName: "square.and.arrow.up")).")
                    .imageScale(.medium)
            }
            HStack {
                Image(systemName: "3.circle.fill")
                Text("Tap \"Share\". (PNG, 1x)")
            }
            HStack {
                Image(systemName: "3.circle.fill")
                Text("Tap \"Set Widget Sprite\".")
            }
        }
        .navigationTitle("Use Widget")
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

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(editorVC: EditorViewController())
    }
}
