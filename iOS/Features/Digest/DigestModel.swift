import CoreMorsel
import Foundation

enum DigestAvailabilityState {
  case locked
  case unlockable
  case unlocked
}

struct DigestConfiguration {
  private enum Keys {
    static let unlockWeekday = "debug_digest_unlock_weekday"
    static let unlockHour = "debug_digest_unlock_hour"
    static let unlockMinute = "debug_digest_unlock_minute"
    static let weekStartWeekday = "debug_digest_week_start_weekday"
    static let weekStartHour = "debug_digest_week_start_hour"
    static let weekStartMinute = "debug_digest_week_start_minute"
  }

  private static let defaults = UserDefaults.standard

  static var unlockWeekday: Int { value(for: Keys.unlockWeekday, default: 2) }
  static var unlockHour: Int { value(for: Keys.unlockHour, default: 12) }
  static var unlockMinute: Int { value(for: Keys.unlockMinute, default: 15) }
  static var weekStartWeekday: Int { value(for: Keys.weekStartWeekday, default: 2) }
  static var weekStartHour: Int { value(for: Keys.weekStartHour, default: 0) }
  static var weekStartMinute: Int { value(for: Keys.weekStartMinute, default: 0) }

  static func clearOverrides() {
    [Keys.unlockWeekday, Keys.unlockHour, Keys.unlockMinute, Keys.weekStartWeekday,
     Keys.weekStartHour, Keys.weekStartMinute].forEach { defaults.removeObject(forKey: $0) }
  }

  static func setWeekStart(weekday: Int, hour: Int, minute: Int) {
    defaults.set(weekday, forKey: Keys.weekStartWeekday)
    defaults.set(hour, forKey: Keys.weekStartHour)
    defaults.set(minute, forKey: Keys.weekStartMinute)
  }

  static func setUnlock(weekday: Int, hour: Int, minute: Int) {
    defaults.set(weekday, forKey: Keys.unlockWeekday)
    defaults.set(hour, forKey: Keys.unlockHour)
    defaults.set(minute, forKey: Keys.unlockMinute)
  }

  private static func value(for key: String, default defaultValue: Int) -> Int {
    defaults.object(forKey: key) == nil ? defaultValue : defaults.integer(forKey: key)
  }
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
    let weekStart = calendar.startOfWeek(for: date)
    let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
    let inclusiveWeekEnd = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: weekStart)!
    return (weekStart, weekEnd, inclusiveWeekEnd)
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
      let checkStart = calendar.startOfWeek(for: checkDate)
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
