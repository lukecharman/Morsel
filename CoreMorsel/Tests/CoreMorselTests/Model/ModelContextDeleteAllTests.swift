@testable import CoreMorsel
import SwiftData
import Testing

@MainActor
struct ModelContextDeleteAllTests {
  @Test func removesAllObjects() async throws {
    let container = try ModelContainer(for: [FoodEntry.self])
    let context = container.mainContext

    context.insert(FoodEntry(name: "A", isForMorsel: false))
    context.insert(FoodEntry(name: "B", isForMorsel: true))
    try context.save()
    let before = try context.fetch(FetchDescriptor<FoodEntry>()).count
    #expect(before == 2)

    let result = context.deleteAll(FoodEntry.self)
    #expect(result)

    let after = try context.fetch(FetchDescriptor<FoodEntry>()).count
    #expect(after == 0)
  }
}
