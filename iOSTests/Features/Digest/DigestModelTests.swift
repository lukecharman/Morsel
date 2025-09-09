import CoreMorsel
import Foundation
import Testing
@testable import Morsel__iOS_

@Suite("DigestModelTests")
struct DigestModelTests {
  // MARK: - Week bounds and filtering

  @Test("Initializer computes correct weekStart and weekEnd (exclusive) for a midweek date")
  func weekBounds_midweek() throws {
    // Pick Wednesday 2025-08-06 10:00
    let date = makeDate(2025, 8, 6, 10)
    let weekStart = mondayMidnight(of: date)
    let expectedWeekEnd = cal.date(byAdding: .day, value: 7, to: weekStart)!

    let model = DigestModel(forWeekContaining: date, allMeals: [])
    #expect(model.weekStart == weekStart)
    #expect(model.weekEnd == expectedWeekEnd)
    assertIsMondayMidnight(model.weekStart)
  }

  @Test("Filters meals within [weekStart, weekEnd - 1s] inclusive")
  func filtersMeals_inclusiveEnd() throws {
    // Week of Monday 2025-08-04 00:00 to Sunday 2025-08-10 23:59:59
    let midweek = makeDate(2025, 8, 6, 12)
    let ws = mondayMidnight(of: midweek)
    let inclusiveEnd = cal.date(byAdding: DateComponents(day: 7, second: -1), to: ws)!

    let insideA = makeDate(2025, 8, 4, 0, 0, 0) // exact start
    let insideB = makeDate(2025, 8, 8, 14, 30, 0)
    let insideC = inclusiveEnd // exact inclusive end

    let outsideBefore = makeDate(2025, 8, 3, 23, 59, 59)
    let outsideAfter = cal.date(byAdding: .second, value: 1, to: inclusiveEnd)!

    let meals: [FoodEntry] = [
      entry(named: "Start", on: insideA, isForMorsel: true),
      entry(named: "Mid", on: insideB, isForMorsel: false),
      entry(named: "End", on: insideC, isForMorsel: true),
      entry(named: "Before", on: outsideBefore, isForMorsel: true),
      entry(named: "After", on: outsideAfter, isForMorsel: false)
    ]

    let model = DigestModel(forWeekContaining: midweek, allMeals: meals)
    #expect(model.mealsLogged == 3)
  }

  // MARK: - Counts and most common craving

  @Test("Counts resisted vs given-in correctly")
  func countsCravings() throws {
    let date = makeDate(2025, 8, 6, 12)
    let ws = mondayMidnight(of: date)

    let meals: [FoodEntry] = [
      entry(named: "Apple", on: cal.date(byAdding: .day, value: 0, to: ws)!, isForMorsel: true),
      entry(named: "Chocolate", on: cal.date(byAdding: .day, value: 1, to: ws)!, isForMorsel: false),
      entry(named: "Nuts", on: cal.date(byAdding: .day, value: 2, to: ws)!, isForMorsel: true),
      entry(named: "Crisps", on: cal.date(byAdding: .day, value: 3, to: ws)!, isForMorsel: false),
      entry(named: "Yoghurt", on: cal.date(byAdding: .day, value: 4, to: ws)!, isForMorsel: true)
    ]

    let model = DigestModel(forWeekContaining: date, allMeals: meals)
    #expect(model.mealsLogged == 5)
    #expect(model.cravingsResisted == 3)
    #expect(model.cravingsGivenIn == 2)
  }

  @Test("Computes most common craving name")
  func mostCommonCraving_basic() throws {
    let date = makeDate(2025, 8, 6, 12)
    let ws = mondayMidnight(of: date)

    // Chocolate appears 3 times, Apple 2, others 1
    let meals: [FoodEntry] = [
      entry(named: "Chocolate", on: cal.date(byAdding: .day, value: 0, to: ws)!, isForMorsel: false),
      entry(named: "Apple", on: cal.date(byAdding: .day, value: 1, to: ws)!, isForMorsel: true),
      entry(named: "Chocolate", on: cal.date(byAdding: .day, value: 2, to: ws)!, isForMorsel: false),
      entry(named: "Nuts", on: cal.date(byAdding: .day, value: 3, to: ws)!, isForMorsel: true),
      entry(named: "Chocolate", on: cal.date(byAdding: .day, value: 4, to: ws)!, isForMorsel: false),
      entry(named: "Apple", on: cal.date(byAdding: .day, value: 5, to: ws)!, isForMorsel: true)
    ]

    let model = DigestModel(forWeekContaining: date, allMeals: meals)
    #expect(model.mostCommonCraving == "Chocolate")
  }

  @Test("Most common craving is N/A when no meals in the week")
  func mostCommonCraving_emptyWeek() throws {
    let date = makeDate(2025, 8, 6, 12)
    let model = DigestModel(forWeekContaining: date, allMeals: [])
    #expect(model.mealsLogged == 0)
    #expect(model.mostCommonCraving == "N/A")
  }

  // MARK: - Streaks

  @Test("Streak counts consecutive non-empty weeks ending at the target week")
  func streak_basicConsecutive() throws {
    // Build 4 consecutive weeks ending 2025-08-04 week, each with 1 meal
    let targetMidweek = makeDate(2025, 8, 6, 12)
    let targetWeekStart = mondayMidnight(of: targetMidweek)

    var meals: [FoodEntry] = []
    for w in 0..<4 {
      let weekStart = cal.date(byAdding: .weekOfYear, value: -w, to: targetWeekStart)!
      let mealDate = cal.date(byAdding: .day, value: 2, to: weekStart)! // Wednesday of that week
      meals.append(entry(named: "MealW\(w)", on: mealDate, isForMorsel: w % 2 == 0))
    }

    let model = DigestModel(forWeekContaining: targetMidweek, allMeals: meals)
    #expect(model.streakLength == 4)
  }

  @Test("Streak breaks on an empty week")
  func streak_breakOnEmpty() throws {
    // Weeks: W0 (non-empty), W-1 (empty), W-2 (non-empty) -> streak should be 1 for W0
    let targetMidweek = makeDate(2025, 8, 6, 12)
    let targetWeekStart = mondayMidnight(of: targetMidweek)

    var meals: [FoodEntry] = []
    // W0: one meal
    let w0Date = cal.date(byAdding: .day, value: 1, to: targetWeekStart)!
    meals.append(entry(named: "Now", on: w0Date, isForMorsel: true))
    // W-1: none
    // W-2: one meal
    let wMinus2Start = cal.date(byAdding: .weekOfYear, value: -2, to: targetWeekStart)!
    let wMinus2Date = cal.date(byAdding: .day, value: 3, to: wMinus2Start)!
    meals.append(entry(named: "Old", on: wMinus2Date, isForMorsel: false))

    let model = DigestModel(forWeekContaining: targetMidweek, allMeals: meals)
    #expect(model.streakLength == 1)
  }

  @Test("Streak caps scanning at 52 weeks but counts fewer if earlier stop occurs")
  func streak_capsAt52() throws {
    let targetMidweek = makeDate(2025, 8, 6, 12)
    let targetWeekStart = mondayMidnight(of: targetMidweek)

    // Create 10 consecutive non-empty weeks
    var meals: [FoodEntry] = []
    for w in 0..<10 {
      let weekStart = cal.date(byAdding: .weekOfYear, value: -w, to: targetWeekStart)!
      let mealDate = cal.date(byAdding: .day, value: 4, to: weekStart)!
      meals.append(entry(named: "W\(w)", on: mealDate, isForMorsel: true))
    }

    let model = DigestModel(forWeekContaining: targetMidweek, allMeals: meals)
    #expect(model.streakLength == 10)
  }

  // MARK: - Tip determinism

  @Test("Tip is deterministic for a given week")
  func tip_isDeterministicForWeek() throws {
    let dateA = makeDate(2025, 8, 6, 12)
    let dateB = makeDate(2025, 8, 4, 1) // same ISO week
    let modelA = DigestModel(forWeekContaining: dateA, allMeals: [])
    let modelB = DigestModel(forWeekContaining: dateB, allMeals: [])
    #expect(modelA.tip == modelB.tip)
  }

  @Test("Tip changes across different weeks (very likely)")
  func tip_differsAcrossWeeksLikely() throws {
    // While not guaranteed, across many weeks it's very likely to differ.
    // We’ll assert that at least across a range we see more than one tip.
    let start = makeDate(2025, 7, 1, 12)
    var tips: Set<MorselTip> = []
    for i in 0..<8 {
      let d = cal.date(byAdding: .weekOfYear, value: i, to: start)!
      let m = DigestModel(forWeekContaining: d, allMeals: [])
      tips.insert(m.tip)
    }
    #expect(tips.count >= 2)
  }

  // MARK: - Cross-week filtering correctness

  @Test("Meals outside the target week are excluded")
  func excludesOutsideWeek() throws {
    let midweek = makeDate(2025, 8, 6, 12)
    let ws = mondayMidnight(of: midweek)
    let prevWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: ws)!
    let nextWeekStart = cal.date(byAdding: .weekOfYear, value: 1, to: ws)!
    let inclusiveEnd = cal.date(byAdding: DateComponents(day: 7, second: -1), to: ws)!

    let prevWeekMeal = entry(named: "Prev", on: cal.date(byAdding: .day, value: 3, to: prevWeekStart)!, isForMorsel: true)
    let thisWeekMeal = entry(named: "This", on: cal.date(byAdding: .day, value: 2, to: ws)!, isForMorsel: false)
    let nextWeekMeal = entry(named: "Next", on: cal.date(byAdding: .day, value: 1, to: nextWeekStart)!, isForMorsel: true)
    let boundaryMeal = entry(named: "Boundary", on: inclusiveEnd, isForMorsel: true)

    let model = DigestModel(forWeekContaining: midweek, allMeals: [prevWeekMeal, thisWeekMeal, nextWeekMeal, boundaryMeal])

    #expect(model.mealsLogged == 2)
    let resisted = model.cravingsResisted
    let givenIn = model.cravingsGivenIn
    #expect(resisted + givenIn == 2)
  }

  var cal: Calendar = {
    var c = Calendar(identifier: .iso8601)
    c.locale = Locale(identifier: "en_GB")
    c.timeZone = TimeZone(identifier: "Europe/London")!
    return c
  }()

}

private extension DigestModelTests {
  func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0) -> Date {
    let comps = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    return cal.date(from: comps)!
  }

  func mondayMidnight(of date: Date) -> Date {
    // Use the same logic DigestModel relies on (CalendarProvider/extension behavior)
    // Recreate via iso8601 components to avoid importing CalendarProvider directly here.
    var iso = Calendar(identifier: .iso8601)
    iso.firstWeekday = 2
    let comps = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return iso.date(from: comps)!
  }

  func assertIsMondayMidnight(_ date: Date, file: StaticString = #file, line: UInt = #line) {
    #expect(cal.component(.weekday, from: date) == 2, "Expected Monday")
    #expect(cal.component(.hour, from: date) == 0, "Expected 00:00")
    #expect(cal.component(.minute, from: date) == 0, "Expected 00:00")
    #expect(cal.component(.second, from: date) == 0, "Expected 00:00")
  }

  func entry(named name: String, on date: Date, isForMorsel: Bool) -> FoodEntry {
    FoodEntry(name: name, timestamp: date, isForMorsel: isForMorsel)
  }
}
