import Foundation

public struct LogForMeEvent: Event {
  public let name = "log_for_me"
  public let parameters: EventParameters

  public init(mealName: String, timestamp: Date, context: String) {
    parameters = [
      "name": mealName,
      "timestamp": timestamp.isoString,
      "context": context
    ]
  }
}
