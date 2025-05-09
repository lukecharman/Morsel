import Foundation
import SwiftData

@MainActor
struct Adder {
  enum Context: String {
    case phoneApp
    case phoneWidget
    case phoneIntent
    case phoneFromWatch
    case watchApp
    case watchFromPhone
  }

  static func add(
    id: String? = nil,
    name: String,
    timestamp: Date = Date(),
    isForMorsel: Bool,
    context: Context
  ) async throws {
    let container = ModelContainer.sharedContainer
    let model = FoodEntry(id: buildUUID(id: id), name: name, timestamp: timestamp, isForMorsel: isForMorsel)
    container.mainContext.insert(model)
    try container.mainContext.save()

    let event = CreateEntryEvent(entry: model, context: context)
    Analytics.track(event)
  }

  static func add(
    id: UUID,
    name: String,
    timestamp: Date = Date(),
    isForMorsel: Bool,
    context: Context
  ) async throws {
    try await add(id: id.uuidString, name: name, timestamp: timestamp, isForMorsel: isForMorsel, context: context)
  }
}

private extension Adder {
  static func buildUUID(id: String?) -> UUID {
    if let id {
      return UUID(uuidString: id) ?? UUID()
    } else {
      return UUID()
    }
  }
}
