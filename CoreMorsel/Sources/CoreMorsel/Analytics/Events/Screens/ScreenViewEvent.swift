import Foundation

public protocol ScreenViewEvent: Event {
  var screenName: String { get }
  var additionalParameters: EventParameters { get }
}

public extension ScreenViewEvent {
  var additionalParameters: EventParameters {
    [:]
  }

  var name: String {
    "ScreenView_\(screenName)"
  }

  var parameters: EventParameters {
    additionalParameters
  }
}
