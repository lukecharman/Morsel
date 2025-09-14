import CoreMorsel
import Foundation
import Testing

@testable import Morsel__iOS_

@Suite("DigestModelBuilder")
struct DigestModelBuilderTests {
  let provider = CalendarProvider(
    timeZone: TimeZone(secondsFromGMT: 0)!,
    locale: Locale(identifier: "en_US_POSIX"))
  let cal: Calendar = {
    var c = Calendar(identifier: .iso8601)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    c.locale = Locale(identifier: "en_US_POSIX")
    return c
  }()

  @Test func digestAtOffset_filtersMealsAndCalculatesStreak() async throws {
    guard let weekStart = makeDate(2024, 2, 26),
      let startMeal = makeDate(2024, 2, 26, 0, 0, 0),
      let leapMeal = makeDate(2024, 2, 29, 12),
      let endMeal = makeDate(2024, 3, 3, 23, 59, 59),
      let outsideMeal = makeDate(2024, 3, 4),
      let prevWeek = makeDate(2024, 2, 19, 9),
      let twoWeeks = makeDate(2024, 2, 12, 9)
    else {
      Issue.record("Failed to create date")
      return
    }

    let meals = [
      FoodEntry(name: "start", timestamp: startMeal),
      FoodEntry(name: "leap", timestamp: leapMeal),
      FoodEntry(name: "end", timestamp: endMeal),
      FoodEntry(name: "outside", timestamp: outsideMeal),
      FoodEntry(name: "prev", timestamp: prevWeek),
      FoodEntry(name: "older", timestamp: twoWeeks),
    ]

    let builder = DigestModelBuilder(meals: meals, calendarProvider: provider)
    let nowStart = provider.startOfDigestWeek(for: Date())
    let offset =
      provider.dateComponents([.weekOfYear], from: weekStart, to: nowStart).weekOfYear ?? 0

    let digest = builder.digest(at: offset)

    #expect(digest.weekStart == weekStart)
    let expectedEnd = provider.date(byAdding: .day, value: 7, to: weekStart)!
    #expect(digest.weekEnd == expectedEnd)
    #expect(digest.mealsLogged == 3)
    #expect(digest.streakLength == 3)
  }

  @Test func digestStreakStopsAtEmptyWeek() async throws {
    guard let weekStart = makeDate(2024, 3, 4),
      let currentMeal = makeDate(2024, 3, 4, 9),
      let oldMeal = makeDate(2024, 2, 19, 9)
    else {
      Issue.record("Failed to create date")
      return
    }

    let meals = [
      FoodEntry(name: "current", timestamp: currentMeal),
      FoodEntry(name: "old", timestamp: oldMeal),
    ]

    let builder = DigestModelBuilder(meals: meals, calendarProvider: provider)
    let nowStart = provider.startOfDigestWeek(for: Date())
    let offset =
      provider.dateComponents([.weekOfYear], from: weekStart, to: nowStart).weekOfYear ?? 0

    let digest = builder.digest(at: offset)
    #expect(digest.streakLength == 1)
  }

  @Test func digestIncludesStartAndInclusiveEnd() async throws {
    guard let weekStart = makeDate(2024, 5, 6),
      let startMeal = makeDate(2024, 5, 6, 0, 0, 0),
      let endMeal = provider.date(
        byAdding: DateComponents(day: 6, hour: 23, minute: 59, second: 59), to: weekStart),
      let afterWeek = provider.date(byAdding: .day, value: 7, to: weekStart)
    else {
      Issue.record("Failed to create date")
      return
    }

    let meals = [
      FoodEntry(name: "start", timestamp: startMeal),
      FoodEntry(name: "end", timestamp: endMeal),
      FoodEntry(name: "after", timestamp: afterWeek),
    ]

    let builder = DigestModelBuilder(meals: meals, calendarProvider: provider)
    let nowStart = provider.startOfDigestWeek(for: Date())
    let offset =
      provider.dateComponents([.weekOfYear], from: weekStart, to: nowStart).weekOfYear ?? 0

    let digest = builder.digest(at: offset)
    #expect(digest.mealsLogged == 2)
  }
}

extension DigestModelBuilderTests {
  fileprivate func makeDate(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0
  ) -> Date? {
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = day
    comps.hour = hour
    comps.minute = minute
    comps.second = second
    return cal.date(from: comps)
  }
}
