import WidgetKit
import SwiftUI

struct QuickLogProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuickLogEntry {
    QuickLogEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
    completion(QuickLogEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
    let entry = QuickLogEntry(date: Date())
    let timeline = Timeline(entries: [entry], policy: .never)
    completion(timeline)
  }
}

struct QuickLogEntry: TimelineEntry {
  let date: Date
}

struct QuickLogView: View {
  var entry: QuickLogEntry

  var body: some View {
    Text("+")
      .widgetCurvesContent()
      .widgetLabel("Morsels")
      .widgetURL(URL(string: "morsel://add")!)
  }
}

@main
struct WatchWidgets: Widget {
  let kind: String = "QuickLogComplication"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuickLogProvider()) { entry in
      QuickLogView(entry: entry)
    }
    .supportedFamilies([
      .accessoryCorner,
    ])
    .configurationDisplayName("Quick Log")
    .description("Quickly add a meal from your watch.")
  }
}
