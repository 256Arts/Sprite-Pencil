//
//  Widget.swift
//  Widget
//
//  Created by 256 Arts Developer on 2020-10-02.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import WidgetKit
import SwiftUI
import SpritePencilKit
import AppIntents

struct SpriteWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Background"
    static var description = IntentDescription("Selects the background fill")

    @Parameter(title: "Fill", default: false)
    var fill: Bool
}

struct SpriteTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = SpriteEntry
    typealias Intent = SpriteWidgetConfiguration
    
    func placeholder(in context: Context) -> SpriteEntry {
        SpriteEntry(date: Date(), configuration: SpriteWidgetConfiguration())
    }

    func snapshot(for configuration: SpriteWidgetConfiguration, in context: Context) async -> SpriteEntry {
        SpriteEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: SpriteWidgetConfiguration, in context: Context) async -> Timeline<SpriteEntry> {
        let entry = SpriteEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .never)
    }
}

struct SpriteEntry: TimelineEntry {
    let date: Date
    let configuration: SpriteWidgetConfiguration
}

struct SpriteWidgetView: View {
    var entry: SpriteTimelineProvider.Entry
    let defaults = UserDefaults(suiteName: "group.com.jaydenirwin.spritepencil")
    var image: UIImage? {
        if let data = defaults?.data(forKey: "sprite") {
            return UIImage(data: data)
        }
        return nil
    }
    var backgroundColor: UIColor {
        if let hex = defaults?.string(forKey: "backgroundColor"), let comp = ColorComponents(hex: hex) {
            return UIColor(components: comp)
        }
        return .black
    }

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: entry.configuration.fill ? .fill : .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(Color(backgroundColor), for: .widget)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("No Sprite Set".uppercased())
                    .font(Font.system(size: 16))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                HStack {
                    Text("Tap")
                    Image(systemName: "square.and.arrow.up")
                }
                Text("Tap \"Share\"")
                Text("Tap \"Set Widget Sprite\"")
            }
            .font(Font.system(size: 17))
            .containerBackground(.primary, for: .widget)
        }
    }
}

@main
struct SpriteWidget: Widget {
    let kind: String = "Widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SpriteWidgetConfiguration.self, provider: SpriteTimelineProvider()) { entry in
            SpriteWidgetView(entry: entry)
        }
        .configurationDisplayName("Sprite")
        .description("Display a sprite.")
        .containerBackgroundRemovable(false)
    }
}

struct SpriteWidget_Previews: PreviewProvider {
    static var previews: some View {
        SpriteWidgetView(entry: SpriteEntry(date: Date(), configuration: SpriteWidgetConfiguration()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
