import Foundation
import Testing
@testable import Morsel__iOS_

@Suite("Calendar+MorselTests")
struct Calendar_MorselTests {
  @Test("Monday at midnight returns same Monday midnight")
  func mondayMidnight() throws {
    guard let date = makeDate(2025, 8, 4, 0, 0, 0) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 8)
    #expect(cal.component(.day, from: result) == 4)
    assertIsMondayMidnight(result)
  }

  @Test("Sunday 23:59 maps to previous Monday")
  func sundayLateMapsToPreviousMonday() throws {
    guard let date = makeDate(2025, 8, 3, 23, 59, 59) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 7)
    #expect(cal.component(.day, from: result) == 28)
    assertIsMondayMidnight(result)
  }

  @Test("Midweek samples map to same Monday")
  func midweekSamples() throws {
    guard let tue = makeDate(2025, 8, 5, 9, 30, 0),
          let thu = makeDate(2025, 8, 7, 18, 45, 10) else { Issue.record("Failed to build date(s)"); return }
    let r1 = cal.startOfWeek(for: tue)
    let r2 = cal.startOfWeek(for: thu)
    #expect(r1 == r2)
    #expect(cal.component(.day, from: r1) == 4)
    #expect(cal.component(.month, from: r1) == 8)
    assertIsMondayMidnight(r1)
    assertIsMondayMidnight(r2)
  }

  // MARK: - Idempotence / invariants

  @Test("Idempotent when applied to its own result")
  func idempotent() throws {
    guard let date = makeDate(2025, 8, 8, 20, 14, 0) else { Issue.record("Failed to build date"); return }
    let r1 = cal.startOfWeek(for: date)
    let r2 = cal.startOfWeek(for: r1)
    #expect(r1 == r2)
    assertIsMondayMidnight(r1)
  }

  @Test("Same Monday for all days in a given ISO week")
  func sameForAllDaysInWeek() throws {
    guard let monday = makeDate(2025, 8, 4, 10),
          let tuesday = makeDate(2025, 8, 5, 10),
          let wednesday = makeDate(2025, 8, 6, 10),
          let thursday = makeDate(2025, 8, 7, 10),
          let friday = makeDate(2025, 8, 8, 10),
          let saturday = makeDate(2025, 8, 9, 10),
          let sunday = makeDate(2025, 8, 10, 10) else { Issue.record("Failed to build date(s)"); return }
    let results = [monday, tuesday, wednesday, thursday, friday, saturday, sunday].map { cal.startOfWeek(for: $0) }
    for r in results { assertIsMondayMidnight(r) }
    #expect(Set(results).count == 1)
    #expect(cal.component(.day, from: results[0]) == 4)
  }

  // MARK: - Year boundaries & ISO week edges

  @Test("New Year’s Day belonging to previous ISO week")
  func newYearBelongsToPreviousISOWeek() throws {
    // 2021-01-01 (Fri) -> Monday 2020-12-28
    guard let date = makeDate(2021, 1, 1, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2020)
    #expect(cal.component(.month, from: result) == 12)
    #expect(cal.component(.day, from: result) == 28)
    assertIsMondayMidnight(result)
  }

  @Test("Jan 1, 2015 maps to Monday 2014-12-29")
  func jan1_2015_isoWeek1Edge() throws {
    guard let date = makeDate(2015, 1, 1, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2014)
    #expect(cal.component(.month, from: result) == 12)
    #expect(cal.component(.day, from: result) == 29)
    assertIsMondayMidnight(result)
  }

  @Test("New Year that starts on Monday")
  func newYearStartsOnMonday() throws {
    // 2018-01-01 (Mon) -> same Monday
    guard let date = makeDate(2018, 1, 1, 9) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2018)
    #expect(cal.component(.month, from: result) == 1)
    #expect(cal.component(.day, from: result) == 1)
    assertIsMondayMidnight(result)
  }

  @Test("New Year Sunday maps to previous Monday")
  func newYearSundayMapsToPreviousMonday() throws {
    // 2017-01-01 (Sun) -> Monday 2016-12-26
    guard let date = makeDate(2017, 1, 1, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2016)
    #expect(cal.component(.month, from: result) == 12)
    #expect(cal.component(.day, from: result) == 26)
    assertIsMondayMidnight(result)
  }

  @Test("End of year in ISO week 53")
  func endOfYearWeek53() throws {
    // 2020-12-31 (Thu) -> Monday 2020-12-28
    guard let date = makeDate(2020, 12, 31, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2020)
    #expect(cal.component(.month, from: result) == 12)
    #expect(cal.component(.day, from: result) == 28)
    assertIsMondayMidnight(result)
  }

  // MARK: - Leap year / February edges

  @Test("Leap day maps to the correct Monday")
  func leapDay() throws {
    // 2024-02-29 (Thu) -> Monday 2024-02-26
    guard let date = makeDate(2024, 2, 29, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2024)
    #expect(cal.component(.month, from: result) == 2)
    #expect(cal.component(.day, from: result) == 26)
    assertIsMondayMidnight(result)
  }

  @Test("Non-leap late February maps correctly")
  func nonLeapLateFeb() throws {
    // 2019-02-28 (Thu) -> Monday 2019-02-25
    guard let date = makeDate(2019, 2, 28, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2019)
    #expect(cal.component(.month, from: result) == 2)
    #expect(cal.component(.day, from: result) == 25)
    assertIsMondayMidnight(result)
  }

  // MARK: - DST boundaries (Europe/London)

  @Test("Week containing spring forward")
  func weekContainingSpringForward() throws {
    // UK DST starts on Sun 2025-03-30; choose a safe hour
    guard let date = makeDate(2025, 3, 30, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 3)
    #expect(cal.component(.day, from: result) == 24)
    assertIsMondayMidnight(result)
  }

  @Test("Week containing fall back")
  func weekContainingFallBack() throws {
    // UK DST ends on Sun 2025-10-26; choose a safe hour
    guard let date = makeDate(2025, 10, 26, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 10)
    #expect(cal.component(.day, from: result) == 20)
    assertIsMondayMidnight(result)
  }

  // MARK: - Month boundaries

  @Test("Across month boundary but within same month’s Monday")
  func acrossMonthBoundarySameMonthMonday() throws {
    // Sat 2025-08-09 -> Monday 2025-08-04
    guard let date = makeDate(2025, 8, 9, 23, 59, 59) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 8)
    #expect(cal.component(.day, from: result) == 4)
    assertIsMondayMidnight(result)
  }

  @Test("Across month boundary into the previous month")
  func acrossMonthBoundaryIntoPreviousMonth() throws {
    // Sun 2025-03-02 -> Monday 2025-02-24
    guard let date = makeDate(2025, 3, 2, 12) else { Issue.record("Failed to build date"); return }
    let result = cal.startOfWeek(for: date)
    #expect(cal.component(.year, from: result) == 2025)
    #expect(cal.component(.month, from: result) == 2)
    #expect(cal.component(.day, from: result) == 24)
    assertIsMondayMidnight(result)
  }

  // Use ISO-8601 weeks (Monday as first day) and a fixed timezone to avoid CI drift.
  var cal: Calendar = {
    var c = Calendar(identifier: .iso8601)
    c.locale = Locale(identifier: "en_GB")
    c.timeZone = TimeZone(identifier: "Europe/London")!
    return c
  }()
}

private extension Calendar_MorselTests {
  func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0) -> Date? {
    let comps = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    return cal.date(from: comps)
  }

  func assertIsMondayMidnight(_ date: Date, file: StaticString = #file, line: UInt = #line) {
    #expect(cal.component(.weekday, from: date) == 2, "Expected Monday")
    #expect(cal.component(.hour, from: date) == 0, "Expected 00:00")
    #expect(cal.component(.minute, from: date) == 0, "Expected 00:00")
    #expect(cal.component(.second, from: date) == 0, "Expected 00:00")
  }
}
