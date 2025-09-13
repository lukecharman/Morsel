import Foundation
import CoreMorsel

struct DigestWeekBuilder {
  private let calendar: Calendar
  private let calendarProvider: CalendarProvider

  init(calendar: Calendar = .current, calendarProvider: CalendarProvider = CalendarProvider()) {
    self.calendar = calendar
    self.calendarProvider = calendarProvider
  }

  func availableOffsets(for meals: [FoodEntry]) -> [Int] {
    // If no meals, preserve legacy behavior: include last week and this week.
    guard let earliestMealDate = meals.map(\.timestamp).min() else {
      return [1, 0]
    }

    let startOfCurrentWeek = calendarProvider.startOfDigestWeek(for: Date())
    let startOfEarliestMealWeek = calendarProvider.startOfDigestWeek(for: earliestMealDate)

    // Build contiguous week starts from earliest meal week to current week (inclusive)
    var weekStarts: [Date] = []
    var cursor = startOfEarliestMealWeek
    while cursor <= startOfCurrentWeek {
      weekStarts.append(cursor)
      // Safe add 1 week
      guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
      cursor = next
    }

    // Determine which weeks are non-empty
    // For efficiency, compute each week’s inclusive end (start + 7d - 1s)
    let weekRanges: [(start: Date, endInclusive: Date)] = weekStarts.map { ws in
      let end = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: ws)!
      return (start: ws, endInclusive: end)
    }

    func hasMeals(in range: (start: Date, endInclusive: Date)) -> Bool {
      // Fast path: if no meals at all, already handled above.
      // Basic filter; meals array is expected to be modest in size for client-side filtering.
      meals.contains { $0.timestamp >= range.start && $0.timestamp <= range.endInclusive }
    }

    // Find index of first non-empty week
    let firstNonEmptyIndex = weekRanges.firstIndex(where: { hasMeals(in: $0) })

    // If somehow no non-empty weeks are found (shouldn't happen because earliest was from a meal),
    // fall back to returning just [0] (current week). But to be safe, keep legacy [1, 0].
    guard let nonEmptyIdx = firstNonEmptyIndex else {
      return [1, 0]
    }

    // Trim leading empties, but keep exactly one empty week before the first non-empty if any existed.
    let firstIndexToKeep: Int = max(0, nonEmptyIdx - 1)
    let trimmedWeekStarts = Array(weekStarts[firstIndexToKeep...])

    // Map week starts to offsets relative to current week (0 = current)
    // offset = number of weeks between weekStart and currentWeekStart
    let offsets: [Int] = trimmedWeekStarts.compactMap { ws in
      let comps = calendar.dateComponents([.weekOfYear], from: ws, to: startOfCurrentWeek)
      return comps.weekOfYear
    }

    // We built offsets oldest->newest; return in descending order (like previous code): [max ... 0]
    return offsets.sorted(by: >)
  }
}
