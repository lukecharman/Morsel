import CoreMorsel
import Foundation

enum DigestSeason { case winter, spring, summer, autumn }
enum DigestMood { case noMeals, strong, tough, balanced }

enum DigestAvailabilityState {
  case locked
  case unlockable
  case unlocked
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
  let calendarProvider: CalendarProviderInterface

  init(
    weekStart: Date,
    weekEnd: Date,
    meals: [FoodEntry],
    streakLength: Int,
    calendarProvider: CalendarProviderInterface = CalendarProvider()
  ) {
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
    self.calendarProvider = calendarProvider
  }

  var season: DigestSeason {
    let m = calendarProvider.component(.month, from: weekStart)
    switch m {
    case 12, 1, 2: return .winter
    case 3, 4, 5: return .spring
    case 6, 7, 8: return .summer
    default: return .autumn
    }
  }

  var mood: DigestMood {
    if mealsLogged == 0 { return .noMeals }
    if cravingsResisted > cravingsGivenIn { return .strong }
    if cravingsGivenIn > cravingsResisted { return .tough }
    return .balanced
  }

  var encouragement: String {
    let state: DigestEncouragementState
    if mealsLogged == 0 {
      state = .noMeals
    } else if cravingsResisted > cravingsGivenIn {
      state = .moreResisted
    } else if cravingsGivenIn > cravingsResisted {
      state = .moreGivenIn
    } else {
      state = .balanced
    }
    return state.messages.randomElement() ?? ""
  }

  var formattedRange: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE d MMM"
    let displayEnd = calendarProvider.date(byAdding: .day, value: -1, to: weekEnd) ?? weekEnd
    return "\(formatter.string(from: weekStart)) – \(formatter.string(from: displayEnd))"
  }

  var title: String {
    let week = calendarProvider.component(.weekOfYear, from: weekStart)
    let year = calendarProvider.component(.yearForWeekOfYear, from: weekStart)
    let seed = week + year * 1000 + streakLength * 100_000
    var rng = SeededGenerator(seed: seed)

    let s = season
    let m = mood

    var pool: [String] = []
    pool.append(contentsOf: DigestTitleGenerator.titles[m]?[s] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.moodOnly[m] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.seasonOnly[s] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.generic)

    let dynamicCandidates = DigestTitleGenerator.dynamicTitles(
      mostCommonCraving: mostCommonCraving,
      streak: streakLength,
      meals: mealsLogged,
      resisted: cravingsResisted,
      gaveIn: cravingsGivenIn,
      season: s,
      mood: m
    )
    pool.append(contentsOf: dynamicCandidates)

    if pool.isEmpty { return "Weekly Digest" }
    let index = Int(rng.next() % UInt64(pool.count))
    return "“" + pool[index] + "”"
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
