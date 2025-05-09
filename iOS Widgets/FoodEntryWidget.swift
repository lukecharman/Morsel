import WidgetKit
import SwiftUI
import SwiftData

struct FoodEntryWidget: Widget {
  let kind: String = "FoodEntryWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FoodTimelineProvider()) { entry in
      FoodEntryWidgetView(entry: entry)
    }
    .configurationDisplayName("Food Log")
    .description("View your recent food entries and quickly add new ones.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
