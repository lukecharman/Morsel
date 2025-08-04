import Foundation

public struct LogForMorselEvent: Event {
  public let name = "log_for_morsel"
  public let parameters: EventParameters

  public init(craving: String, timestamp: Date, context: String) {
    parameters = [
      "name": craving,
      "timestamp": timestamp.isoString,
      "context": context
    ]
  }
}
