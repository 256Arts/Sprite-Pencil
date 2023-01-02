//
//  HelpView.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2020-10-25.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            NavigationLink("Tools") {
                ToolsHelpView()
            }
            NavigationLink("Create A Palette") {
                CreatePaletteHelpView()
            }
            NavigationLink("Use Widget") {
                WidgetHelpView()
            }
        }
        .navigationTitle("Help")
        .imageScale(.large)
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
                        Text("Helps drawing gradients by only editing every other pixel.")
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
        }
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

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
