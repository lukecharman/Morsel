@testable import CoreMorsel
import Foundation
import Testing

struct NotificationNameMorselTests {
  @Test func hasExpectedRawValue() async throws {
    #expect(Notification.Name.didReceiveMorselColor.rawValue == "didReceiveMorselColor")
  }
}
