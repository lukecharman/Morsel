import CoreMorsel
import Foundation
import SwiftData

@MainActor
struct StatsModel {
  let modelContainer: ModelContainer
  let calendarProvider: CalendarProviderInterface

  init(modelContainer: ModelContainer, calendarProvider: CalendarProviderInterface = CalendarProvider()) {
    self.modelContainer = modelContainer
    self.calendarProvider = calendarProvider
  }

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

  var averageMorselPercentagePerDay: Int {
    let descriptor = FetchDescriptor<FoodEntry>()
    guard let entries = try? modelContainer.mainContext.fetch(descriptor), !entries.isEmpty else { return 0 }

    /// 1. Group entries by day using a consistent calendar
    let grouped = Dictionary(grouping: entries) {
      calendarProvider.startOfDay(for: $0.timestamp)
    }

    /// 2. Calculate daily percentages
    let dailyPercentages: [Double] = grouped.values.map { dayEntries in
      guard !dayEntries.isEmpty else { return 0 }
      let morselCount = dayEntries.filter { $0.isForMorsel }.count
      return Double(morselCount) / Double(dayEntries.count)
    }

    /// 3. Average
    let total = dailyPercentages.reduce(0, +)
    return Int((total / Double(dailyPercentages.count)) * 100)
  }
}

private extension StatsModel {
  func streaks(from sortedUniqueDays: [Date]) -> (longest: Int, current: Int) {
    guard var previousDay = sortedUniqueDays.first else { return (0, 0) }

    /// Calculate longest streak across all days
    var longest = 1
    var running = 1
    for day in sortedUniqueDays.dropFirst() {
      let expected = calendarProvider.date(byAdding: .day, value: -1, to: previousDay)!
      if calendarProvider.isDate(day, inSameDayAs: expected) {
        running += 1
      } else {
        longest = max(longest, running)
        running = 1
      }
      previousDay = day
    }
    longest = max(longest, running)

    /// Calculate current streak starting from today if present
    var current = 0
    if let first = sortedUniqueDays.first, calendarProvider.isDate(first, inSameDayAs: Date()) {
      current = 1
      previousDay = first
      for day in sortedUniqueDays.dropFirst() {
        let expected = calendarProvider.date(byAdding: .day, value: -1, to: previousDay)!
        if calendarProvider.isDate(day, inSameDayAs: expected) {
          current += 1
          previousDay = day
        } else {
          break
        }
      }
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

    let days = entries.map { calendarProvider.startOfDay(for: $0.timestamp) }

    return Array(Set(days)).sorted(by: >)
  }
}
