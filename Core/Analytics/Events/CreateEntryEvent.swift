import Foundation

struct CreateEntryEvent: Event {
  let entry: FoodEntry

  var name: String {
    "CreateEntry"
  }

  var parameters: EventParameters {
    [
      "name": entry.name,
      "timestamp": entry.timestamp.description,
      "isForMorsel": entry.isForMorsel.description
    ]
  }
}
