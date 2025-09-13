import Foundation
import CoreMorsel

struct DigestModelBuilder {
  private let meals: [FoodEntry]
  private let calendarProvider: CalendarProviderInterface

  init(meals: [FoodEntry], calendarProvider: CalendarProviderInterface = CalendarProvider()) {
    self.meals = meals
    self.calendarProvider = calendarProvider
  }

  func digest(at offset: Int) -> DigestModel {
    let baseDate = calendarProvider.date(byAdding: .weekOfYear, value: -offset, to: Date())!
    let bounds = weekBounds(for: baseDate)

    let mealsForWeek = meals.filter { $0.timestamp >= bounds.start && $0.timestamp <= bounds.inclusiveEnd }
    let streak = consecutiveNonEmptyWeeks(endingAt: bounds.start)

    return DigestModel(weekStart: bounds.start, weekEnd: bounds.end, meals: mealsForWeek, streakLength: streak)
  }
}

private extension DigestModelBuilder {
  func weekBounds(for date: Date) -> (start: Date, end: Date, inclusiveEnd: Date) {
    let start = calendarProvider.startOfDigestWeek(for: date)
    let end = calendarProvider.date(byAdding: .day, value: 7, to: start)!
    let inclusiveEnd = calendarProvider.date(byAdding: DateComponents(day: 7, second: -1), to: start)!
    return (start, end, inclusiveEnd)
  }

  func consecutiveNonEmptyWeeks(endingAt weekStart: Date) -> Int {
    let maxWeeksBack = 52
    var streak = 0
    for i in 0..<maxWeeksBack {
      guard let checkDate = calendarProvider.date(byAdding: .weekOfYear, value: -i, to: weekStart) else { break }
      let checkStart = calendarProvider.startOfDigestWeek(for: checkDate)
      let checkEnd = calendarProvider.date(byAdding: DateComponents(day: 7, second: -1), to: checkStart)!
      let mealsInWeek = meals.filter { $0.timestamp >= checkStart && $0.timestamp <= checkEnd }
      if mealsInWeek.isEmpty {
        break
      } else {
        streak += 1
      }
    }
    return streak
  }
}
