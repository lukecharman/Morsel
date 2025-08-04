import Foundation

public struct ScreenViewFilledEntries: ScreenViewEvent {
  public let screenName = "FilledEntries"
  public let count: Int

  public init(count: Int) {
    self.count = count
  }

  public var additionalParameters: EventParameters {
    [
      "entry_count": count.description
    ]
  }
}
