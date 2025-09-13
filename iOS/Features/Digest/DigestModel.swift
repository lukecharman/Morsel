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

  var formattedRange: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM"
    let calendar = Calendar.current
    let displayEnd = calendar.date(byAdding: .day, value: -1, to: weekEnd) ?? weekEnd
    return "\(formatter.string(from: weekStart)) – \(formatter.string(from: displayEnd))"
  }

  init(weekStart: Date, weekEnd: Date, meals: [FoodEntry], streakLength: Int) {
    let (mealsLogged, cravingsResisted, cravingsGivenIn) = Self.computeCravingCounts(from: meals)
    let mostCommonCraving = Self.mostCommonCraving(from: meals)
    let tip = Self.generateTip(for: weekStart)

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

  static func generateTip(for weekStart: Date) -> MorselTip {
    let secondsPerWeek: TimeInterval = 7 * 24 * 60 * 60
    let weekIndex = Int(weekStart.timeIntervalSince1970 / secondsPerWeek)
    let seed = weekIndex

    var generator = SeededGenerator(seed: seed)

    return MorselTip.allCases.randomElement(using: &generator)!
  }
}
