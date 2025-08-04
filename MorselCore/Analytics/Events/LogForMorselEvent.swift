import Foundation

struct LogForMorselEvent: Event {
  let craving: FoodEntry
  let context: AddContext

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
