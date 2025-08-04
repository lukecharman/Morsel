import Foundation

struct LogForMeEvent: Event {
  let meal: FoodEntry
  let context: AddContext

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
