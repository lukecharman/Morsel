import Foundation

typealias EventParameters = [String: String]

protocol Event {
  var name: String { get }
  var parameters: EventParameters { get }
}

extension Event {
  var parameters: EventParameters {
    [:]
  }
}

