import Foundation

struct DeleteForMeEvent: Event {
  let meal: FoodEntry

  var name: String {
    "delete_for_me"
  }

  var parameters: EventParameters {
    [
      "name": meal.name,
      "timestamp": meal.timestamp.isoString
    ]
  }
}
