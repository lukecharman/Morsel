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

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Today’s Meals")
        .font(.headline)
        .foregroundStyle(.primary)
        .padding(.vertical, 4)

      if entry.foodEntries.isEmpty {
        Text("No meals yet.")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        ForEach(entry.foodEntries.prefix(3), id: \.id) { foodEntry in
          HStack(spacing: 8) {
            Image(systemName: "fork.knife")
              .font(.caption2)
              .foregroundStyle(.secondary)
            Text(foodEntry.name)
              .font(.subheadline)
              .lineLimit(1)
              .foregroundStyle(.primary)
          }
        }
      }

      Spacer()

      HStack {
        Spacer()
        HStack {
          Spacer()
          VStack {
            Spacer()
            StaticMorsel()
          }
        }
        .frame(height: 40)
      }
      .widgetURL(URL(string: "morsel://add")!)
    }
    .containerBackground(.fill.tertiary, for: .widget)
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
        FoodEntrySnapshot(id: entry.id, name: entry.name, timestamp: entry.timestamp)
      }
    } catch {
      print("⚠️ Error fetching food entries for widget: \(error)")
      return []
    }
  }
}

struct FoodEntrySnapshot: Identifiable, Codable {
  var id: UUID
  var name: String
  var timestamp: Date
}

#Preview(as: .systemSmall) {
  FoodEntryWidget()
} timeline: {
  FoodEntryTimelineEntry(date: .now, foodEntries: [])
}
