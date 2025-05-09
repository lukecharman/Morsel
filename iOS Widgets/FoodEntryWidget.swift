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

struct FoodEntryWidgetView: View {
  var entry: FoodEntryTimelineEntry

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetFamily) private var widgetFamily

  var body: some View {
    ZStack {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(
            widgetFamily == .systemSmall
              ? "Today (\(entry.foodEntries.count))"
              : "Today's Morsels (\(entry.foodEntries.count))"
          )
          .font(widgetFamily == .systemSmall ?  MorselFont.widgetTitle : MorselFont.title)
            .foregroundStyle(.primary)
            .padding(.bottom, 8)
            .contentTransition(.numericText())

          if entry.foodEntries.isEmpty {
            Text("Nothin' yet.")
              .font(MorselFont.body)
              .font(.caption)
              .foregroundStyle(.secondary)
          } else {
            switch widgetFamily {
            case .systemSmall:
              column(for: Array(entry.foodEntries.prefix(3)))

            default:
              let entries = Array(entry.foodEntries.prefix(6))
              let firstColumnEntries = entries.indices
                .filter { $0 % 2 == 0 }
                .map { entries[$0] }

              let secondColumnEntries = entries.indices
                .filter { $0 % 2 != 0 }
                .map { entries[$0] }

              HStack(alignment: .top, spacing: 16) {
                column(for: firstColumnEntries)
                  .frame(maxWidth: .infinity, alignment: .leading)

                column(for: secondColumnEntries)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
          Spacer()
        }
        Spacer()
      }
      GeometryReader { geo in
        Link(destination: URL(string: "morsel://add")!) {
          StaticMorsel()
        }
        .frame(
          width: widgetFamily == .systemSmall ? 40 : 40,
          height: widgetFamily == .systemSmall ? 40 : 40
        )
        .position(
          x: geo.size.width - (widgetFamily == .systemSmall ? 22 : 36),
          y: geo.size.height - (widgetFamily == .systemSmall ? 18 : 26)
        )
      }
    }
    .ignoresSafeArea()
    .widgetURL(URL(string: "morsel://list")!)
    .containerBackground(for: .widget) {
      LinearGradient(
        colors: GradientColors.gradientColors(colorScheme: colorScheme),
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }

  func column(for entries: [FoodEntrySnapshot]) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      ForEach(entries, id: \.id) { foodEntry in
        HStack(spacing: 8) {
          Image(systemName: foodEntry.isForMorsel ? "face.smiling.fill" : "person.fill")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(foodEntry.name)
            .font(widgetFamily == .systemSmall ?  MorselFont.widgetBody : MorselFont.body)
            .lineLimit(1)
            .opacity(foodEntry.isForMorsel ? 0.5 : 1)
            .foregroundStyle(.primary)
        }
      }
    }
  }
}

struct FoodEntryTimelineEntry: TimelineEntry {
  let date: Date
  let foodEntries: [FoodEntrySnapshot]
}

struct FoodTimelineProvider: @preconcurrency TimelineProvider {
  func placeholder(in context: Context) -> FoodEntryTimelineEntry {
    FoodEntryTimelineEntry(date: Date(), foodEntries: [])
  }

  func getSnapshot(in context: Context, completion: @escaping (FoodEntryTimelineEntry) -> ()) {
    let entry = FoodEntryTimelineEntry(date: Date(), foodEntries: [])
    completion(entry)
  }

  @MainActor
  func getTimeline(in context: Context, completion: @escaping (Timeline<FoodEntryTimelineEntry>) -> ()) {
    Task {
      let entries = await fetchTodayFoodEntries()
      let timelineEntry = FoodEntryTimelineEntry(date: Date(), foodEntries: entries)

      let nextRefresh: Date = entries.isEmpty
      ? Calendar.current.date(byAdding: .minute, value: 60, to: Date())!
      : Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

      completion(Timeline(entries: [timelineEntry], policy: .after(nextRefresh)))
    }
  }

  @MainActor
  private func fetchTodayFoodEntries() async -> [FoodEntrySnapshot] {
    do {
      let container: ModelContainer = .sharedContainer
      let context = container.mainContext

      let calendar = Calendar.current
      let startOfDay = calendar.startOfDay(for: Date())
      let predicate = #Predicate<FoodEntry> { entry in
        entry.timestamp >= startOfDay
      }

      let descriptor = FetchDescriptor<FoodEntry>(
        predicate: predicate,
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
      )

      let entries = try context.fetch(descriptor)

      return entries.map { entry in
        FoodEntrySnapshot(id: entry.id, name: entry.name, timestamp: entry.timestamp, isForMorsel: entry.isForMorsel)
      }
    } catch {
      return []
    }
  }
}

struct FoodEntrySnapshot: Identifiable, Codable {
  var id: UUID = UUID()
  var name: String
  var timestamp: Date = Date()
  var isForMorsel: Bool = false
}

#Preview(as: .systemMedium, widget: {
  FoodEntryWidget()
}, timeline: {
  FoodEntryTimelineEntry(date: .now, foodEntries: [
    FoodEntrySnapshot(name: "Toast")
  ])
  FoodEntryTimelineEntry(date: .now, foodEntries: [
    FoodEntrySnapshot(name: "Toast"),
    FoodEntrySnapshot(name: "Chocolate Bar", isForMorsel: true)
  ])
  FoodEntryTimelineEntry(date: .now, foodEntries: [
    FoodEntrySnapshot(name: "Toast"),
    FoodEntrySnapshot(name: "Chocolate Bar", isForMorsel: true),
    FoodEntrySnapshot(name: "Egg Sandwich"),
    FoodEntrySnapshot(name: "Tomatoes", isForMorsel: true),
    FoodEntrySnapshot(name: "Haribo"),
    FoodEntrySnapshot(name: "Pistachios")
  ])
})
