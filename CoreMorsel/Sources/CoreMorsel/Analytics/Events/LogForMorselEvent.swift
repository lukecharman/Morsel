import Foundation

public struct LogForMorselEvent: Event {
  public let name = "log_for_morsel"
  public let parameters: EventParameters

  public init(cravingName: String, timestamp: Date, context: String) {
    parameters = [
      "name": cravingName,
      "timestamp": timestamp.isoString,
      "context": context
    ]
  }
}
