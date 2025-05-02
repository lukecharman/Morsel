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
    let container: ModelContainer = .sharedContainer
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
    default:
      QuickLogNoCountCornerView()
    }
  }
}

struct QuickLogCornerView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    Text("\(entry.mealCount)")
      .font(.system(size: 12, weight: .bold))
      .widgetCurvesContent()
      .widgetLabel("Log Meal")
      .widgetURL(URL(string: "morsel://add")!)
      .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct QuickLogNoCountCornerView: View {
  var body: some View {
    Image(systemName: "plus")
      .font(.system(size: 12, weight: .bold))
      .widgetCurvesContent()
      .widgetLabel("Log Meal")
      .widgetURL(URL(string: "morsel://add")!)
      .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct QuickLogCircularView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    ZStack {
      Circle().fill(.white.opacity(0.1))
      VStack {
        Text("\(entry.mealCount)")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.white)
        Text("Log")
          .font(.footnote)
          .widgetCurvesContent()
      }
    }
    .widgetLabel("Log")
    .widgetURL(URL(string: "morsel://add")!)
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct QuickLogNoCountCircularView: View {
  var body: some View {
    ZStack {
      Circle().fill(.white.opacity(0.1))
      VStack {
        StaticMorsel()
        Text("Log")
          .font(.footnote)
          .widgetCurvesContent()
      }
    }
    .widgetURL(URL(string: "morsel://add")!)
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct QuickLogRectangularView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    HStack {
      Image(systemName: "fork.knife.circle.fill")
        .foregroundColor(.accentColor)
      VStack(alignment: .leading) {
        Text("Log Meal")
          .font(.headline)
        Text("Today: \(entry.mealCount)")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .widgetURL(URL(string: "morsel://add")!)
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct QuickLogInlineView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    Text("Meals today: \(entry.mealCount)")
      .widgetURL(URL(string: "morsel://add")!)
      .containerBackground(.fill.tertiary, for: .widget)
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
