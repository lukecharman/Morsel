import Foundation

struct DeleteForMorselEvent: Event {
  let craving: FoodEntry

  var name: String {
    "delete_for_morsel"
  }

  var parameters: EventParameters {
    [
      "name": craving.name,
      "timestamp": craving.timestamp.isoString
    ]
  }
}
