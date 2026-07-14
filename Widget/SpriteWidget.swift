import WidgetKit
import SwiftUI
import SpritePencilKit
import AppIntents

struct SpriteWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Background"
    static let description = IntentDescription("Selects the background fill")

    @Parameter(title: "Fill", default: false)
    var fill: Bool
}

struct SpriteTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = SpriteEntry
    typealias Intent = SpriteWidgetConfiguration
    
    func placeholder(in context: Context) -> SpriteEntry {
        SpriteEntry(date: Date(), configuration: SpriteWidgetConfiguration(), imageData: nil, backgroundColorHex: nil)
    }

    func snapshot(for configuration: SpriteWidgetConfiguration, in context: Context) async -> SpriteEntry {
        makeEntry(for: configuration)
    }

    func timeline(for configuration: SpriteWidgetConfiguration, in context: Context) async -> Timeline<SpriteEntry> {
        Timeline(entries: [makeEntry(for: configuration)], policy: .never)
    }

    // Snapshot the app-group state into the entry so the view renders from a
    // captured value instead of re-reading defaults at render time.
    private func makeEntry(for configuration: SpriteWidgetConfiguration) -> SpriteEntry {
        let defaults = AppGroup.defaults
        return SpriteEntry(
            date: Date(),
            configuration: configuration,
            imageData: defaults?.data(forKey: AppGroup.Key.sprite),
            backgroundColorHex: defaults?.string(forKey: AppGroup.Key.backgroundColor)
        )
    }
}

struct SpriteEntry: TimelineEntry {
    let date: Date
    let configuration: SpriteWidgetConfiguration
    let imageData: Data?
    let backgroundColorHex: String?
}

struct SpriteWidgetView: View {
    var entry: SpriteTimelineProvider.Entry
    private var image: UIImage? {
        guard let data = entry.imageData else { return nil }
        return UIImage(data: data)
    }
    private var backgroundColor: UIColor {
        if let hex = entry.backgroundColorHex, let comp = ColorComponents(hex: hex) {
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
                Text("No Sprite Set")
                    .textCase(.uppercase)
                    .font(Font.system(size: 16))
                    .foregroundStyle(.secondary)
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

#Preview(as: .systemSmall) {
    SpriteWidget()
} timeline: {
    SpriteEntry(date: Date(), configuration: SpriteWidgetConfiguration(), imageData: nil, backgroundColorHex: nil)
}
