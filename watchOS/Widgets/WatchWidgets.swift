import CoreMorsel
import WidgetKit
import SwiftUI
import SwiftData

struct QuickLogWithCountProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuickLogWithCountEntry {
    QuickLogWithCountEntry(date: Date(), mealCount: 0)
  }

  func getSnapshot(in context: Context, completion: @escaping (QuickLogWithCountEntry) -> Void) {
    completion(QuickLogWithCountEntry(date: Date(), mealCount: 0))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogWithCountEntry>) -> Void) {
    let container: ModelContainer = .morsel
    var mealCount = 0

    let context = ModelContext(container)
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())
    let descriptor = FetchDescriptor<FoodEntry>(
      predicate: #Predicate { $0.timestamp >= startOfToday }
    )
    if let fetched = try? context.fetch(descriptor) {
      mealCount = fetched.count
    }

    let entry = QuickLogWithCountEntry(date: Date(), mealCount: mealCount)
    let timeline = Timeline(entries: [entry], policy: .never)
    completion(timeline)
  }
}

struct QuickLogNoCountProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuickLogNoCountEntry {
    QuickLogNoCountEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (QuickLogNoCountEntry) -> Void) {
    completion(QuickLogNoCountEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogNoCountEntry>) -> Void) {
    let entry = QuickLogNoCountEntry(date: Date())
    let timeline = Timeline(entries: [entry], policy: .never)
    completion(timeline)
  }
}

struct QuickLogNoCountEntry: TimelineEntry {
  let date: Date
}

struct QuickLogWithCountEntry: TimelineEntry {
  let date: Date
  let mealCount: Int
}

struct QuickLogWithCountView: View {
  var entry: QuickLogWithCountEntry
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

struct QuickLogNoCountView: View {
  var entry: QuickLogNoCountEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .accessoryCorner:
      QuickLogNoCountCornerView()
    case .accessoryCircular:
      QuickLogNoCountCircularView()
    case .accessoryInline:
      QuickLogNoCountInlineView()
    default:
      QuickLogNoCountCornerView()
    }
  }
}

struct QuickLogWithCountWidget: Widget {
  let kind: String = "QuickLogComplication"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuickLogWithCountProvider()) { entry in
      QuickLogWithCountView(entry: entry)
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

struct QuickLogNoCountWidget: Widget {
  let kind: String = "QuickLogNoCountComplication"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuickLogNoCountProvider()) { entry in
      QuickLogNoCountView(entry: entry)
    }
    .supportedFamilies([
      .accessoryCorner,
      .accessoryCircular
    ])
    .configurationDisplayName("Quick Log (No Count)")
    .description("Quickly add a meal from your watch without showing a total.")
  }
}

@main
struct WatchWidgetBundle: WidgetBundle {
  var body: some Widget {
    QuickLogWithCountWidget()
    QuickLogNoCountWidget()
  }
}

#Preview(as: .accessoryCircular, widget: {
  QuickLogWithCountWidget()
}, timeline: {
  QuickLogWithCountEntry(date: Date(), mealCount: 0)
  QuickLogWithCountEntry(date: Date().addingTimeInterval(200), mealCount: 1)
  QuickLogWithCountEntry(date: Date().addingTimeInterval(400), mealCount: 2)
})

