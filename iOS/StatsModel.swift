import Foundation
import SwiftData

@MainActor
struct StatsModel {
  let modelContainer: ModelContainer

  var totalEntries: Int {
    let descriptor = FetchDescriptor<FoodEntry>()
    return (try? modelContainer.mainContext.fetchCount(descriptor)) ?? 0
  }

  var totalEntriesForMorsel: Int {
    let descriptor = FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.isForMorsel == true } )
    return (try? modelContainer.mainContext.fetchCount(descriptor)) ?? 0
  }

  var totalEntriesForMe: Int {
    let descriptor = FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.isForMorsel == false } )
    return (try? modelContainer.mainContext.fetchCount(descriptor)) ?? 0
  }

  var longestStreak: Int {
    let days = uniqueEntryDays()
    return streaks(from: days).longest
  }

  var currentStreak: Int {
    let days = uniqueEntryDays()
    return streaks(from: days).current
  }
}

private extension StatsModel {
  func streaks(from sortedUniqueDays: [Date]) -> (longest: Int, current: Int) {
    let calendar = Calendar.current

    var longest = 0
    var current = 0
    var streak = 0

    var previousDay: Date?

    for day in sortedUniqueDays {
      if let prev = previousDay {
        let expectedNext = calendar.date(byAdding: .day, value: -1, to: prev)!
        if calendar.isDate(day, inSameDayAs: expectedNext) {
          streak += 1
        } else {
          streak = 1
        }
      } else {
        streak = 1
      }

      // Check if the streak includes today (for current)
      if current == 0, calendar.isDate(day, inSameDayAs: Date()) {
        current = streak
      } else if current > 0 {
        // Continue the current streak only if the days are continuous
        let expectedNext = calendar.date(byAdding: .day, value: -1, to: previousDay!)!
        if calendar.isDate(day, inSameDayAs: expectedNext) {
          current = streak
        } else {
          // streak broke
          current = 0
        }
      }

      longest = max(longest, streak)
      previousDay = day
    }

    return (longest, current)
  }

  func uniqueEntryDays() -> [Date] {
    let descriptor = FetchDescriptor<FoodEntry>(
      sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    guard let entries = try? modelContainer.mainContext.fetch(descriptor) else {
      return []
    }

    let calendar = Calendar.current
    let days = entries.map { calendar.startOfDay(for: $0.timestamp) }

    return Array(Set(days)).sorted(by: >)
  }
}
