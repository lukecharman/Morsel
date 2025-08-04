import Foundation

public struct DeleteForMorselEvent: Event {
  public let name = "delete_for_morsel"
  public let parameters: EventParameters

  public init(cravingName: String, timestamp: Date) {
    parameters = [
      "name": cravingName,
      "timestamp": timestamp.isoString
    ]
  }
}
