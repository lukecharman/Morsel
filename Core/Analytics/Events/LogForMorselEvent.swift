import Foundation

struct LogForMorselEvent: Event {
  let craving: FoodEntry
  let context: Adder.Context

  var name: String {
    "log_for_morsel"
  }

  var parameters: EventParameters {
    [
      "name": craving.name,
      "timestamp": craving.timestamp.isoString,
      "context": context.rawValue
    ]
  }
}
