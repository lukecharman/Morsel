import Foundation
import Testing
@testable import Morsel__iOS_

struct DigestTimeCalculatorTests {
  // UK-anchored calendar for determinism in CI
  var cal: Calendar = {
    var c = Calendar(identifier: .iso8601)
    c.locale = Locale(identifier: "en_GB")
    c.timeZone = TimeZone(identifier: "Europe/London")!
    return c
  }()

  private func makeDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, _ s: Int = 0) -> Date? {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))
  }

  @Test func unlockTime_isMonday1215_forPlainWeek() async throws {
    // Week of 2025-08-04 (Mon)
    guard let weekStart = makeDate(2025, 8, 4, 0, 0, 0) else { Issue.record("Invalid date"); return }
    let unlock = DigestTimeCalculator.unlockTime(for: weekStart, calendar: cal)
    #expect(cal.component(.weekday, from: unlock) == 2)
    #expect(cal.component(.hour, from: unlock) == 12)
    #expect(cal.component(.minute, from: unlock) == 15)
    #expect(cal.component(.second, from: unlock) == 0)
    #expect(cal.component(.year, from: unlock) == 2025)
    #expect(cal.component(.month, from: unlock) == 8)
    #expect(cal.component(.day, from: unlock) == 4)
  }

  @Test func unlockTime_isMonday1215_weekWithSpringDST() async throws {
    // UK DST starts Sun 2025-03-30; target week is 2025-03-24..30
    guard let weekStart = makeDate(2025, 3, 24, 0, 0, 0) else { Issue.record("Invalid date"); return }
    let unlock = DigestTimeCalculator.unlockTime(for: weekStart, calendar: cal)
    #expect(cal.component(.weekday, from: unlock) == 2)
    #expect(cal.component(.hour, from: unlock) == 12)
    #expect(cal.component(.minute, from: unlock) == 15)
    #expect(cal.component(.second, from: unlock) == 0)
    #expect(cal.component(.year, from: unlock) == 2025)
    #expect(cal.component(.month, from: unlock) == 3)
    #expect(cal.component(.day, from: unlock) == 24)
  }

  @Test func unlockTime_isMonday1215_weekWithFallDST() async throws {
    // UK DST ends Sun 2025-10-26; target week is 2025-10-20..26
    guard let weekStart = makeDate(2025, 10, 20, 0, 0, 0) else { Issue.record("Invalid date"); return }
    let unlock = DigestTimeCalculator.unlockTime(for: weekStart, calendar: cal)
    #expect(cal.component(.weekday, from: unlock) == 2)
    #expect(cal.component(.hour, from: unlock) == 12)
    #expect(cal.component(.minute, from: unlock) == 15)
    #expect(cal.component(.second, from: unlock) == 0)
    #expect(cal.component(.year, from: unlock) == 2025)
    #expect(cal.component(.month, from: unlock) == 10)
    #expect(cal.component(.day, from: unlock) == 20)
  }
}

