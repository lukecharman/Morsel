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
    VStack(alignment: .leading) {
      if entry.foodEntries.isEmpty {
        Text("No entries yet.")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        ForEach(entry.foodEntries.prefix(3)) { foodEntry in
          Text(foodEntry.name)
            .font(.footnote)
            .lineLimit(1)
        }
      }

      Spacer()

      Text("+ Add Entry")
        .font(.caption2)
        .foregroundColor(.blue)
        .widgetURL(URL(string: "morsel://add")!)
    }
    .padding()
    .containerBackground(
      RadialGradient(
        colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
        center: .center,
        startRadius: 20,
        endRadius: 300
      ),
      for: .widget)
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
      let timeline = Timeline(entries: [timelineEntry], policy: .after(Date().addingTimeInterval(900)))
      completion(timeline)
    }
  }

  @MainActor
  private func fetchTodayFoodEntries() async -> [FoodEntrySnapshot] {
    do {
      let container = try ModelContainer.sharedContainer()
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
