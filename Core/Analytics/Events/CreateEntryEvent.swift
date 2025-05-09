import Foundation

struct CreateEntryEvent: Event {
  let entry: FoodEntry
  let context: Adder.Context

  var name: String {
    "CreateEntry"
  }

  var parameters: EventParameters {
    [
      "name": entry.name,
      "timestamp": entry.timestamp.description,
      "isForMorsel": entry.isForMorsel.description,
      "context": context.rawValue
    ]
  }
}
