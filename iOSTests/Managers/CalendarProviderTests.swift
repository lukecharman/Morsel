import Foundation
import Testing
@testable import Morsel__iOS_

struct CalendarProviderTests {
  // Use a stable calendar for deterministic tests (ISO weeks start Monday)
  // and pin to UK time to reflect app expectations and avoid CI tz drift.
  var cal: Calendar = {
    var c = Calendar(identifier: .iso8601)
    c.locale = Locale(identifier: "en_GB")
    c.timeZone = TimeZone(identifier: "Europe/London")!
    return c
  }()

  // MARK: - Helpers
  private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0) -> Date? {
    let comps = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    return cal.date(from: comps)
  }

  private func assertIsMondayMidnight(_ date: Date, file: StaticString = #file, line: UInt = #line) {
    #expect(cal.component(.weekday, from: date) == 2) // Monday
    #expect(cal.component(.hour, from: date) == 0)
    #expect(cal.component(.minute, from: date) == 0)
    #expect(cal.component(.second, from: date) == 0)
  }

  // MARK: - Basic cases
  @Test func startOfWeek_forMondayMidnight() async throws {
    guard let date = makeDate(2025, 8, 4, 0, 0, 0) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 8)
    #expect(cal.component(.day, from: result) == 4)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_forSunday2359() async throws {
    guard let date = makeDate(2025, 8, 3, 23, 59, 59) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 7)
    #expect(cal.component(.day, from: result) == 28)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_forMondayNoon_returnsSameMondayMidnight() async throws {
    guard let date = makeDate(2025, 8, 4, 12, 0, 0) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 8)
    #expect(cal.component(.day, from: result) == 4)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_forMidweekSamples() async throws {
    // Tuesday
    guard let tue = makeDate(2025, 8, 5, 9, 30, 0) else { Issue.record("Date could not be built."); return }
    // Thursday
    guard let thu = makeDate(2025, 8, 7, 18, 45, 10) else { Issue.record("Date could not be built."); return }
    let r1 = CalendarProvider().startOfWeek(for: tue)
    let r2 = CalendarProvider().startOfWeek(for: thu)
    // Both are in the same ISO week -> same Monday (2025-08-04)
    #expect(r1 == r2)
    #expect(cal.component(.day, from: r1) == 4)
    #expect(cal.component(.month, from: r1) == 8)
    assertIsMondayMidnight(r1)
    assertIsMondayMidnight(r2)
  }

  // MARK: - Idempotence & invariants
  @Test func startOfWeek_isIdempotent() async throws {
    guard let date = makeDate(2025, 8, 8, 20, 14, 0) else { Issue.record("Date could not be built."); return }
    let r1 = CalendarProvider().startOfWeek(for: date)
    let r2 = CalendarProvider().startOfWeek(for: r1)
    #expect(r1 == r2)
    assertIsMondayMidnight(r1)
  }

  @Test func startOfWeek_sameForAllDaysInWeek() async throws {
    // Check that every day Mon..Sun maps to the same Monday
    guard let monday = makeDate(2025, 8, 4, 10),
          let tuesday = makeDate(2025, 8, 5, 10),
          let wednesday = makeDate(2025, 8, 6, 10),
          let thursday = makeDate(2025, 8, 7, 10),
          let friday = makeDate(2025, 8, 8, 10),
          let saturday = makeDate(2025, 8, 9, 10),
          let sunday = makeDate(2025, 8, 10, 10) else { Issue.record("Date(s) could not be built."); return }
    let provider = CalendarProvider()
    let results = [monday, tuesday, wednesday, thursday, friday, saturday, sunday].map { provider.startOfWeek(for: $0) }
    for r in results { assertIsMondayMidnight(r) }
    #expect(Set(results).count == 1)
    #expect(cal.component(.day, from: results[0]) == 4)
  }

  // MARK: - Year boundaries & ISO week edges
  @Test func startOfWeek_onNewYearsDayThatBelongsToPreviousYearsWeek() async throws {
    // 2021-01-01 (Fri) -> Monday 2020-12-28
    guard let date = makeDate(2021, 1, 1, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2020)
    #expect(cal.component(.month, from: result) == 12)
    #expect(cal.component(.day, from: result) == 28)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_jan1_2015_isoWeek1Edge() async throws {
    // 2015-01-01 (Thu) -> Monday 2014-12-29
    guard let date = makeDate(2015, 1, 1, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2014)
    #expect(cal.component(.month, from: result) == 12)
    #expect(cal.component(.day, from: result) == 29)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_newYearThatStartsOnMonday() async throws {
    // 2018-01-01 (Mon) -> Monday 2018-01-01
    guard let date = makeDate(2018, 1, 1, 9) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2018)
    #expect(cal.component(.month, from: result) == 1)
    #expect(cal.component(.day, from: result) == 1)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_newYearSundayMapsToPreviousMonday() async throws {
    // 2017-01-01 (Sun) -> Monday 2016-12-26
    guard let date = makeDate(2017, 1, 1, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2016)
    #expect(cal.component(.month, from: result) == 12)
    #expect(cal.component(.day, from: result) == 26)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_endOfYearWeek53() async throws {
    // 2020-12-31 (Thu) is in ISO week 53 -> Monday 2020-12-28
    guard let date = makeDate(2020, 12, 31, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2020)
    #expect(cal.component(.month, from: result) == 12)
    #expect(cal.component(.day, from: result) == 28)
    assertIsMondayMidnight(result)
  }

  // MARK: - Leap year
  @Test func startOfWeek_onLeapDay() async throws {
    // 2024-02-29 (Thu) -> Monday 2024-02-26
    guard let date = makeDate(2024, 2, 29, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2024)
    #expect(cal.component(.month, from: result) == 2)
    #expect(cal.component(.day, from: result) == 26)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_nonLeapLateFeb() async throws {
    // 2019-02-28 (Thu) -> Monday 2019-02-25
    guard let date = makeDate(2019, 2, 28, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2019)
    #expect(cal.component(.month, from: result) == 2)
    #expect(cal.component(.day, from: result) == 25)
    assertIsMondayMidnight(result)
  }

  // MARK: - DST boundaries (Europe/London)
  @Test func startOfWeek_weekContainingSpringForward() async throws {
    // UK DST starts on Sun 2025-03-30; pick noon to avoid nonexistent hour
    guard let date = makeDate(2025, 3, 30, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 3)
    #expect(cal.component(.day, from: result) == 24)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_weekContainingFallBack() async throws {
    // UK DST ends on Sun 2025-10-26; pick noon to avoid ambiguous hour
    guard let date = makeDate(2025, 10, 26, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 10)
    #expect(cal.component(.day, from: result) == 20)
    assertIsMondayMidnight(result)
  }

  // MARK: - Month boundaries
  @Test func startOfWeek_acrossMonthBoundary_backIntoPreviousMonth() async throws {
    // Sat 2025-08-09 -> Monday 2025-08-04 (same month)
    guard let date = makeDate(2025, 8, 9, 23, 59, 59) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 8)
    #expect(cal.component(.day, from: result) == 4)
    assertIsMondayMidnight(result)
  }

  @Test func startOfWeek_acrossMonthBoundary_intoPreviousMonth() async throws {
    // Sun 2025-03-02 -> Monday 2025-02-24
    guard let date = makeDate(2025, 3, 2, 12) else { Issue.record("Date could not be built."); return }
    let result = CalendarProvider().startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 2)
    #expect(cal.component(.day, from: result) == 24)
    assertIsMondayMidnight(result)
  }
}
