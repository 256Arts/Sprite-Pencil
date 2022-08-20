//
//  Widget.swift
//  Widget
//
//  Created by Jayden Irwin on 2020-10-02.
//  Copyright © 2020 Jayden Irwin. All rights reserved.
//

import WidgetKit
import SwiftUI
import SpritePencilKit
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct WidgetEntryView: View {
    var entry: Provider.Entry
    var wantsFill: Bool {
        entry.configuration.fill?.boolValue ?? true
    }
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
                .aspectRatio(contentMode: wantsFill ? .fill : .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(backgroundColor))
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
            .padding()
            .font(Font.system(size: 17))
        }
    }
}

@main
struct SpriteWidget: Widget {
    let kind: String = "Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sprite")
        .description("Display a sprite.")
    }
}

struct SpriteWidget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
