import WidgetKit
import SwiftUI

struct QuickLogProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuickLogEntry {
    QuickLogEntry(date: Date(), mealCount: 0)
  }

  func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
    completion(QuickLogEntry(date: Date(), mealCount: 0))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
    let entry = QuickLogEntry(date: Date(), mealCount: 0)
    let timeline = Timeline(entries: [entry], policy: .never)
    completion(timeline)
  }
}

struct QuickLogEntry: TimelineEntry {
  let date: Date
  let mealCount: Int
}

struct QuickLogView: View {
  var entry: QuickLogEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .accessoryCorner:
      QuickLogCornerView(entry: entry)
    case .accessoryCircular:
      QuickLogCircularView(entry: entry)
    case .accessoryRectangular:
      QuickLogRectangularView(entry: entry)
    case .accessoryInline:
      QuickLogInlineView(entry: entry)
    default:
      QuickLogCornerView(entry: entry)
    }
  }
}

struct QuickLogCornerView: View {
  var entry: QuickLogEntry

  var body: some View {
    Text("+")
      .widgetCurvesContent()
      .widgetLabel("Morsels")
      .widgetURL(URL(string: "morsel://add")!)
  }
}

struct QuickLogCircularView: View {
  var entry: QuickLogEntry

  var body: some View {
    ZStack {
      Circle().fill(.white.opacity(0.1))
      Image(systemName: "plus")
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(.white)
    }
    .widgetURL(URL(string: "morsel://add")!)
  }
}

struct QuickLogRectangularView: View {
  var entry: QuickLogEntry

  var body: some View {
    HStack {
      Image(systemName: "plus")
      Text("Log Meal")
    }
    .padding(.horizontal)
    .widgetURL(URL(string: "morsel://add")!)
  }
}

struct QuickLogInlineView: View {
  var entry: QuickLogEntry

  var body: some View {
    Text("🍴 \(entry.mealCount)")
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
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryInline
    ])
    .configurationDisplayName("Quick Log")
    .description("Quickly add a meal from your watch.")
  }
}
