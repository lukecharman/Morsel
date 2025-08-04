import Testing
import SwiftData
@testable import Morsel__watchOS_

@MainActor
struct WatchContentViewTests {
  @Test func todayPredicateReturnsOnlyTodayEntry() throws {
    let config = ModelConfiguration(inMemory: true)
    let container = try ModelContainer(for: FoodEntry.self, configurations: config)
    let context = container.mainContext
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

    context.insert(FoodEntry(name: "Today", timestamp: today, isForMorsel: false))
    context.insert(FoodEntry(name: "Yesterday", timestamp: yesterday, isForMorsel: false))
    context.insert(FoodEntry(name: "Tomorrow", timestamp: tomorrow, isForMorsel: false))
    try context.save()

    let descriptor = FetchDescriptor<FoodEntry>(predicate: WatchContentView.todayPredicate)
    let results = try context.fetch(descriptor)

    #expect(results.count == 1)
    #expect(results.first?.name == "Today")
  }
}

