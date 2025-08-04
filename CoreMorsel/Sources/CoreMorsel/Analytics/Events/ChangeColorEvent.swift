import Foundation

public struct ChangeColorEvent: Event {
  let newValue: String
  let syncIcon: Bool

  public init(newValue: String, syncIcon: Bool) {
    self.newValue = newValue
    self.syncIcon = syncIcon
  }

  public var name: String {
    "change_color"
  }

  public var parameters: EventParameters {
    [
      "color": newValue,
      "sync_icon": String(syncIcon)
    ]
  }
}
