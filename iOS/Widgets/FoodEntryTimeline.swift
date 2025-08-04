import CoreMorsel
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

struct FoodEntryTimelineEntry: TimelineEntry {
  let date: Date
  let foodEntries: [FoodEntrySnapshot]
  let morselColor: Color
}

struct FoodTimelineProvider: @preconcurrency TimelineProvider {
  func placeholder(in context: Context) -> FoodEntryTimelineEntry {
    FoodEntryTimelineEntry(date: Date(), foodEntries: [], morselColor: loadMorselColor())
  }

  func getSnapshot(in context: Context, completion: @escaping (FoodEntryTimelineEntry) -> ()) {
    let entry = FoodEntryTimelineEntry(date: Date(), foodEntries: [], morselColor: loadMorselColor())
    completion(entry)
  }

  @MainActor
  func getTimeline(in context: Context, completion: @escaping (Timeline<FoodEntryTimelineEntry>) -> ()) {
    Task {
      let entries = await fetchTodayFoodEntries()
      let timelineEntry = FoodEntryTimelineEntry(date: Date(), foodEntries: entries, morselColor: loadMorselColor())

      let nextRefresh: Date = entries.isEmpty
      ? Calendar.current.date(byAdding: .minute, value: 60, to: Date())!
      : Calendar.current.date(byAdding: .minute, value: 15, to: Date())!

      completion(Timeline(entries: [timelineEntry], policy: .after(nextRefresh)))
    }
  }

  @MainActor
  private func fetchTodayFoodEntries() async -> [FoodEntrySnapshot] {
    do {
      let container: ModelContainer = .morsel
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

  private func loadMorselColor() -> Color {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)!

    if let data = defaults.data(forKey: Key.morselColor.rawValue),
       let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
      return Color(uiColor)
    } else {
      return .blue
    }
  }
}
