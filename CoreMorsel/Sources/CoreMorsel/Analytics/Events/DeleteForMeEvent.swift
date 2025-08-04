import Foundation

public struct DeleteForMeEvent: Event {
  public let name = "delete_for_me"
  public let parameters: EventParameters

  public init(mealName: String, timestamp: Date) {
    parameters = [
      "name": mealName,
      "timestamp": timestamp.isoString
    ]
  }
}
