import Foundation

struct LogForMeEvent: Event {
  let meal: FoodEntry
  let context: Adder.Context

  var name: String {
    "log_for_me"
  }

  var parameters: EventParameters {
    [
      "name": meal.name,
      "timestamp": meal.timestamp.isoString,
      "context": context.rawValue
    ]
  }
}
