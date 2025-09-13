import Foundation
import CoreMorsel

protocol DigestBuilderInterface {
  func digest(forOffset offset: Int) -> DigestModel
  func encouragement(for digest: DigestModel) -> String

  func season(for date: Date) -> DigestSeason
  func mood(for digest: DigestModel) -> DigestMood
  func titleForDigest(_ digest: DigestModel) -> String
}

struct DigestBuilder: DigestBuilderInterface {
  let meals: [FoodEntry]

  init(meals: [FoodEntry]) {
    self.meals = meals
  }

  // Public API: build a digest for a given week offset (0 = current week, 1 = last week, etc.)
  func digest(forOffset offset: Int) -> DigestModel {
    let calendar = Calendar.current
    let baseDate = calendar.date(byAdding: .weekOfYear, value: -offset, to: Date())!
    let bounds = weekBounds(for: baseDate)

    let mealsForWeek = meals.filter { $0.timestamp >= bounds.start && $0.timestamp <= bounds.inclusiveEnd }
    let streak = consecutiveNonEmptyWeeks(endingAt: bounds.start)

    return DigestModel(weekStart: bounds.start, weekEnd: bounds.end, meals: mealsForWeek, streakLength: streak)
  }

  func encouragement(for digest: DigestModel) -> String {
    let state: DigestEncouragementState
    if digest.mealsLogged == 0 {
      state = .noMeals
    } else if digest.cravingsResisted > digest.cravingsGivenIn {
      state = .moreResisted
    } else if digest.cravingsGivenIn > digest.cravingsResisted {
      state = .moreGivenIn
    } else {
      state = .balanced
    }
    return state.messages.randomElement() ?? ""
  }

  func season(for date: Date) -> DigestSeason {
    let m = Calendar.current.component(.month, from: date)
    switch m {
    case 12, 1, 2: return .winter
    case 3, 4, 5: return .spring
    case 6, 7, 8: return .summer
    default: return .autumn
    }
  }

  func mood(for digest: DigestModel) -> DigestMood {
    if digest.mealsLogged == 0 { return .noMeals }
    if digest.cravingsResisted > digest.cravingsGivenIn { return .strong }
    if digest.cravingsGivenIn > digest.cravingsResisted { return .tough }
    return .balanced
  }

  func titleForDigest(_ digest: DigestModel) -> String {
    let cal = Calendar.current
    let week = cal.component(.weekOfYear, from: digest.weekStart)
    let year = cal.component(.yearForWeekOfYear, from: digest.weekStart)
    let seed = week + year * 1000 + digest.streakLength * 100_000
    var rng = SeededGenerator(seed: seed)

    let s = season(for: digest.weekStart)
    let m = mood(for: digest)

    var pool: [String] = []
    pool.append(contentsOf: DigestTitleGenerator.titles[m]?[s] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.moodOnly[m] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.seasonOnly[s] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.generic)

    let dynamicCandidates = DigestTitleGenerator.dynamicTitles(
      mostCommonCraving: digest.mostCommonCraving,
      streak: digest.streakLength,
      meals: digest.mealsLogged,
      resisted: digest.cravingsResisted,
      gaveIn: digest.cravingsGivenIn,
      season: s,
      mood: m
    )
    pool.append(contentsOf: dynamicCandidates)

    if pool.isEmpty { return "Weekly Digest" }
    let index = Int(rng.next() % UInt64(pool.count))
    return "“" + pool[index] + "”"
  }
}

private extension DigestBuilder {
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
