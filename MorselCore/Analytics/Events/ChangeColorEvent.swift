import Foundation

struct ChangeColorEvent: Event {
  let newValue: String
  let syncIcon: Bool

  var name: String {
    "change_color"
  }

  var parameters: EventParameters {
    [
      "color": newValue,
      "sync_icon": String(syncIcon)
    ]
  }
}
