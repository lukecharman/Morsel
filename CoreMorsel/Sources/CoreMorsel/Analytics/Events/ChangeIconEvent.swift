import Foundation

public struct ChangeIconEvent: Event {
  let newValue: String

  public init(newValue: String) {
    self.newValue = newValue
  }

  public var name: String {
    "change_icon"
  }

  public var parameters: EventParameters {
    [
      "icon": newValue,
    ]
  }
}
