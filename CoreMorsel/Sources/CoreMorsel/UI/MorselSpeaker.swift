import SwiftUI

@MainActor
public final class MorselSpeaker: ObservableObject {
  @Published public var message: String?

  public init() {}

  public func speak(_ text: String) {
    message = text
  }
}

