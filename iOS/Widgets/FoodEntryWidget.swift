import CoreMorsel
import WidgetKit
import SwiftUI
import SwiftData

struct FoodEntryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "com.lukecharman.morsel.entry", provider: FoodTimelineProvider()) { entry in
      FoodEntryWidgetView(entry: entry)
        .environmentObject(AppSettings.shared)
    }
    .configurationDisplayName("Food Log")
    .description("View your recent food entries and quickly add new ones.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
