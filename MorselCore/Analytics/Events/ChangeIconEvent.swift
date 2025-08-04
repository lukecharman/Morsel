import Foundation

struct ChangeIconEvent: Event {
  let newValue: String

  var name: String {
    "change_icon"
  }

  var parameters: EventParameters {
    [
      "icon": newValue,
    ]
  }
}
