import Foundation

public typealias EventParameters = [String: String]

public protocol Event {
  var name: String { get }
  var parameters: EventParameters { get }
}

public extension Event {
  var parameters: EventParameters {
    [:]
  }
}

