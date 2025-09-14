import CoreMorsel
import Foundation
import Testing

@testable import Morsel__iOS_

@Suite("DigestWeekBuilder")
struct DigestWeekBuilderTests {
  let provider = CalendarProvider(
    timeZone: TimeZone(secondsFromGMT: 0)!,
    locale: Locale(identifier: "en_US_POSIX"))
  let cal: Calendar = {
    var c = Calendar(identifier: .iso8601)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    c.locale = Locale(identifier: "en_US_POSIX")
    return c
  }()

  @Test func noMeals_returnsLastAndCurrentWeek() async throws {
    let builder = DigestWeekBuilder(calendarProvider: provider)
    let result = builder.availableOffsets(for: [])
    #expect(result == [1, 0])
  }

  @Test func singleWeekMeals_returnsCurrentOnly() async throws {
    let meal = FoodEntry(name: "only", timestamp: Date())
    let builder = DigestWeekBuilder(calendarProvider: provider)
    let result = builder.availableOffsets(for: [meal])
    #expect(result == [0])
  }

  @Test func spanningWeeks_includesGapsAndSortsDescending() async throws {
    guard let m1 = makeDate(2024, 2, 26, 12),
      let m2 = makeDate(2024, 3, 10, 12)
    else {
      Issue.record("date")
      return
    }
    let meals = [
      FoodEntry(name: "a", timestamp: m1),
      FoodEntry(name: "b", timestamp: m2),
    ]
    let builder = DigestWeekBuilder(calendarProvider: provider)
    let result = builder.availableOffsets(for: meals)

    let currentStart = provider.startOfDigestWeek(for: Date())
    let firstStart = provider.startOfDigestWeek(for: m1)
    let expectedMax =
      provider.dateComponents([.weekOfYear], from: firstStart, to: currentStart).weekOfYear ?? 0
    #expect(result.first == expectedMax)
    #expect(result.last == 0)
    #expect(result == result.sorted(by: >))
  }

  @Test func handlesMealsAtBoundaryAndLeapDay() async throws {
    guard let sunday = makeDate(2024, 3, 3, 23, 59, 59),
      let leap = makeDate(2024, 2, 29, 0, 0, 1)
    else {
      Issue.record("date")
      return
    }
    let meals = [
      FoodEntry(name: "sunday", timestamp: sunday),
      FoodEntry(name: "leap", timestamp: leap),
    ]
    let builder = DigestWeekBuilder(calendarProvider: provider)
    let result = builder.availableOffsets(for: meals)
    #expect(result.contains(0))
    #expect(!result.isEmpty)
  }
}

extension DigestWeekBuilderTests {
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
