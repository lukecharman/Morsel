import Foundation
import SwiftData
import WidgetKit

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
