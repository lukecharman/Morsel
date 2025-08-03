import Testing
import SwiftData
@testable import Morsel__iOS_

@MainActor
struct StatsModelTests {
  @Test func totalsAndAverage() throws {
    let config = ModelConfiguration(inMemory: true)
    let container = try ModelContainer(for: FoodEntry.self, configurations: config)
    let context = container.mainContext
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
    context.insert(FoodEntry(name: "Meal1", timestamp: today, isForMorsel: true))
    context.insert(FoodEntry(name: "Meal2", timestamp: today, isForMorsel: false))
    context.insert(FoodEntry(name: "Meal3", timestamp: yesterday, isForMorsel: true))
    context.insert(FoodEntry(name: "Meal4", timestamp: twoDaysAgo, isForMorsel: false))
    context.insert(FoodEntry(name: "Meal5", timestamp: twoDaysAgo, isForMorsel: false))
    try context.save()
    let stats = StatsModel(modelContainer: container)
    #expect(stats.totalEntries == 5)
    #expect(stats.totalEntriesForMorsel == 2)
    #expect(stats.totalEntriesForMe == 3)
    #expect(stats.averageMorselPercentagePerDay == 50)
  }

  @Test func streaks() throws {
    let config = ModelConfiguration(inMemory: true)
    let container = try ModelContainer(for: FoodEntry.self, configurations: config)
    let context = container.mainContext
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
    let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today)!
    let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!
    [today, yesterday, threeDaysAgo, fourDaysAgo, fiveDaysAgo].forEach {
      context.insert(FoodEntry(name: "Meal", timestamp: $0))
    }
    try context.save()
    let stats = StatsModel(modelContainer: container)
    #expect(stats.longestStreak == 3)
    #expect(stats.currentStreak == 2)
  }
}

