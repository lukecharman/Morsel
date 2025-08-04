import Foundation
import SwiftData
import WidgetKit

@MainActor
struct Adder {
  static func add(
    id: String? = nil,
    name: String,
    timestamp: Date = Date(),
    isForMorsel: Bool,
    context: AddContext
  ) async throws {
    let container = ModelContainer.morsel
    let model = FoodEntry(
      id: buildUUID(id: id),
      name: name,
      timestamp: timestamp,
      isForMorsel: isForMorsel
    )
    container.mainContext.insert(model)
    try container.mainContext.save()

    WidgetCenter.shared.reloadAllTimelines()

    if isForMorsel {
      let event = LogForMorselEvent(craving: model, context: context)
      Analytics.track(event)
    } else {
      let event = LogForMeEvent(meal: model, context: context)
      Analytics.track(event)
    }
  }

  static func add(
    id: UUID,
    name: String,
    timestamp: Date = Date(),
    isForMorsel: Bool,
    context: AddContext
  ) async throws {
    try await add(
      id: id.uuidString,
      name: name,
      timestamp: timestamp,
      isForMorsel: isForMorsel,
      context: context
    )
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
