import CoreMorsel
import Foundation

enum DigestAvailabilityState {
  case locked
  case unlockable
  case unlocked
}

struct DigestConfiguration {
  static let unlockWeekday = 2 // Monday
  static let unlockHour = 12
  static let unlockMinute = 15
}

struct DigestModel {
  let weekStart: Date
  let weekEnd: Date
  let mealsLogged: Int
  let cravingsResisted: Int
  let cravingsGivenIn: Int
  let mostCommonCraving: String
  let streakLength: Int
  let tip: MorselTip

  init(forWeekContaining date: Date, allMeals: [FoodEntry]) {
    let calendar = Calendar.current
    let (weekStart, weekEnd, inclusiveWeekEnd) = Self.computeWeekBounds(for: date, using: calendar)
    let thisWeeksMeals = Self.filterMeals(in: weekStart...inclusiveWeekEnd, from: allMeals)
    let (mealsLogged, cravingsResisted, cravingsGivenIn) = Self.computeCravingCounts(from: thisWeeksMeals)
    let mostCommonCraving = Self.mostCommonCraving(from: thisWeeksMeals)
    let streakLength = Self.consecutiveNonEmptyWeeks(endingAt: weekStart, allMeals: allMeals, calendar: calendar)
    let tip = Self.generateTip(for: weekStart, using: calendar)

    self.weekStart = weekStart
    self.weekEnd = weekEnd
    self.mealsLogged = mealsLogged
    self.cravingsResisted = cravingsResisted
    self.cravingsGivenIn = cravingsGivenIn
    self.mostCommonCraving = mostCommonCraving
    self.streakLength = streakLength
    self.tip = tip
  }
}

private extension DigestModel {
  static func computeWeekBounds(for date: Date, using calendar: Calendar) -> (weekStart: Date, weekEnd: Date, inclusiveWeekEnd: Date) {
    // Compute week bounds anchored to the configured unlock weekday/time
    let weekStart = mostRecentAnchor(onOrBefore: date, using: calendar)
    let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
    let inclusiveWeekEnd = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: weekStart)!
    return (weekStart, weekEnd, inclusiveWeekEnd)
  }

  /// Returns the most recent anchor instant at or before the given date, based on DigestConfiguration.unlockWeekday/unlockHour/unlockMinute.
  /// Weekday uses the same numbering as Calendar (1=Sunday, 2=Monday, ...).
  static func mostRecentAnchor(onOrBefore date: Date, using calendar: Calendar) -> Date {
    // Build a date on the target weekday in the same week as `date` at the unlock time
    var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .timeZone], from: date)
    components.weekday = DigestConfiguration.unlockWeekday
    components.hour = DigestConfiguration.unlockHour
    components.minute = DigestConfiguration.unlockMinute
    components.second = 0

    // Use ISO-8601 week semantics for (yearForWeekOfYear/weekOfYear) mapping, but preserve the passed calendar's timezone
    var iso = Calendar(identifier: .iso8601)
    iso.timeZone = calendar.timeZone

    // Construct the candidate anchor this week using ISO week/year to avoid locale-dependent firstWeekday
    var weekly = DateComponents()
    weekly.yearForWeekOfYear = components.yearForWeekOfYear
    weekly.weekOfYear = components.weekOfYear
    weekly.weekday = components.weekday
    weekly.hour = components.hour
    weekly.minute = components.minute
    weekly.second = components.second

    let candidateThisWeek = iso.date(from: weekly)!

    if candidateThisWeek <= date {
      return candidateThisWeek
    } else {
      // Go back 7 days to get the previous week's anchor
      return calendar.date(byAdding: .day, value: -7, to: candidateThisWeek)!
    }
  }

  static func filterMeals(in range: ClosedRange<Date>, from allMeals: [FoodEntry]) -> [FoodEntry] {
    allMeals.filter { $0.timestamp >= range.lowerBound && $0.timestamp <= range.upperBound }
  }

  static func computeCravingCounts(from meals: [FoodEntry]) -> (mealsLogged: Int, cravingsResisted: Int, cravingsGivenIn: Int) {
    let mealsLogged = meals.count
    let cravingsResisted = meals.filter { $0.isForMorsel }.count
    let cravingsGivenIn = meals.filter { !$0.isForMorsel }.count
    return (mealsLogged, cravingsResisted, cravingsGivenIn)
  }

  static func mostCommonCraving(from meals: [FoodEntry]) -> String {
    let names = meals.map { $0.name }
    let counts = Dictionary(grouping: names, by: { $0 }).mapValues { $0.count }
    return counts.sorted { $0.value > $1.value }.first?.key ?? "N/A"
  }

  static func generateTip(for weekStart: Date, using calendar: Calendar) -> MorselTip {
    // Deterministic tip per week
    let seed = calendar.component(.weekOfYear, from: weekStart) + calendar.component(.year, from: weekStart) * 100
    var generator = SeededGenerator(seed: seed)
    return MorselTip.allCases.randomElement(using: &generator)!
  }

  static func consecutiveNonEmptyWeeks(endingAt weekStart: Date, allMeals: [FoodEntry], calendar: Calendar) -> Int {
    let maxWeeksBack = 52
    var streak = 0
    for i in 0..<maxWeeksBack {
      guard let checkDate = calendar.date(byAdding: .weekOfYear, value: -i, to: weekStart) else { break }
      // Determine the anchor-based week start for this iteration
      let anchorDate = checkDate
      let checkStart = mostRecentAnchor(onOrBefore: anchorDate, using: calendar)
      let checkEnd = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: checkStart)!
      let mealsInWeek = allMeals.filter { $0.timestamp >= checkStart && $0.timestamp <= checkEnd }
      if mealsInWeek.isEmpty {
        break
      } else {
        streak += 1
      }
    }
    return streak
  }

}
