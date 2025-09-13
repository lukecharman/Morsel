import Foundation
import CoreMorsel

struct DigestModelBuilder {
  private let meals: [FoodEntry]

  init(meals: [FoodEntry]) {
    self.meals = meals
  }

  func digest(forOffset offset: Int) -> DigestModel {
    let calendar = Calendar.current
    let baseDate = calendar.date(byAdding: .weekOfYear, value: -offset, to: Date())!
    let bounds = weekBounds(for: baseDate)

    let mealsForWeek = meals.filter { $0.timestamp >= bounds.start && $0.timestamp <= bounds.inclusiveEnd }
    let streak = consecutiveNonEmptyWeeks(endingAt: bounds.start)

    return DigestModel(weekStart: bounds.start, weekEnd: bounds.end, meals: mealsForWeek, streakLength: streak)
  }
}

private extension DigestModelBuilder {
  func weekBounds(for date: Date) -> (start: Date, end: Date, inclusiveEnd: Date) {
    let calendar = Calendar.current
    let provider = CalendarProvider()
    let start = provider.startOfDigestWeek(for: date)
    let end = calendar.date(byAdding: .day, value: 7, to: start)!
    let inclusiveEnd = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: start)!
    return (start, end, inclusiveEnd)
  }

  func consecutiveNonEmptyWeeks(endingAt weekStart: Date) -> Int {
    let calendar = Calendar.current
    let provider = CalendarProvider()
    let maxWeeksBack = 52
    var streak = 0
    for i in 0..<maxWeeksBack {
      guard let checkDate = calendar.date(byAdding: .weekOfYear, value: -i, to: weekStart) else { break }
      let checkStart = provider.startOfDigestWeek(for: checkDate)
      let checkEnd = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: checkStart)!
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
