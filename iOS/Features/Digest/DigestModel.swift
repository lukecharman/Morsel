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
    let weekStart = calendar.startOfWeek(for: date)
    let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

    // Compute inclusiveWeekEnd after weekStart/weekEnd are set
    let inclusiveWeekEnd = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: weekStart)!
    let thisWeeksMeals = allMeals.filter { $0.timestamp >= weekStart && $0.timestamp <= inclusiveWeekEnd }

    self.weekStart = weekStart
    self.weekEnd = weekEnd
    self.mealsLogged = thisWeeksMeals.count
    self.cravingsResisted = thisWeeksMeals.filter { $0.isForMorsel }.count
    self.cravingsGivenIn = thisWeeksMeals.filter { !$0.isForMorsel }.count

    let cravings = thisWeeksMeals // both “for me” and “for Morsel” are considered cravings context here
    let cravingNames = cravings.map { $0.name }
    let counted = Dictionary(grouping: cravingNames, by: { $0 }).mapValues { $0.count }
    self.mostCommonCraving = counted.sorted { $0.value > $1.value }.first?.key ?? "N/A"

    // Streak = consecutive non-empty weeks ending with this one
    func consecutiveNonEmptyWeeks(endingAt weekStart: Date, allMeals: [FoodEntry], calendar: Calendar) -> Int {
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
    self.streakLength = consecutiveNonEmptyWeeks(endingAt: weekStart, allMeals: allMeals, calendar: calendar)

    // Deterministic tip per week
    let seed = calendar.component(.weekOfYear, from: weekStart) + calendar.component(.year, from: weekStart) * 100
    var generator = SeededGenerator(seed: seed)
    self.tip = MorselTip.allCases.randomElement(using: &generator)!
  }

  init(forDayContaining date: Date, allMeals: [FoodEntry]) {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

    // Compute inclusiveDayEnd after dayStart/dayEnd are set
    let inclusiveDayEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart)!
    let thisDaysMeals = allMeals.filter { $0.timestamp >= dayStart && $0.timestamp <= inclusiveDayEnd }

    self.weekStart = dayStart  // Use weekStart as the period start for consistency
    self.weekEnd = dayEnd      // Use weekEnd as the period end for consistency
    self.mealsLogged = thisDaysMeals.count
    self.cravingsResisted = thisDaysMeals.filter { $0.isForMorsel }.count
    self.cravingsGivenIn = thisDaysMeals.filter { !$0.isForMorsel }.count

    let cravings = thisDaysMeals
    let cravingNames = cravings.map { $0.name }
    let counted = Dictionary(grouping: cravingNames, by: { $0 }).mapValues { $0.count }
    self.mostCommonCraving = counted.sorted { $0.value > $1.value }.first?.key ?? "N/A"

    // Streak = consecutive non-empty days ending with this one
    func consecutiveNonEmptyDays(endingAt dayStart: Date, allMeals: [FoodEntry], calendar: Calendar) -> Int {
      let maxDaysBack = 365
      var streak = 0
      for i in 0..<maxDaysBack {
        guard let checkDate = calendar.date(byAdding: .day, value: -i, to: dayStart) else { break }
        let checkStart = calendar.startOfDay(for: checkDate)
        let checkEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: checkStart)!
        let mealsInDay = allMeals.filter { $0.timestamp >= checkStart && $0.timestamp <= checkEnd }
        if mealsInDay.isEmpty {
          break
        } else {
          streak += 1
        }
      }
      return streak
    }
    self.streakLength = consecutiveNonEmptyDays(endingAt: dayStart, allMeals: allMeals, calendar: calendar)

    // Deterministic tip per day
    let seed = calendar.component(.day, from: dayStart) + calendar.component(.month, from: dayStart) * 100 + calendar.component(.year, from: dayStart) * 10000
    var generator = SeededGenerator(seed: seed)
    self.tip = MorselTip.allCases.randomElement(using: &generator)!
  }
}
