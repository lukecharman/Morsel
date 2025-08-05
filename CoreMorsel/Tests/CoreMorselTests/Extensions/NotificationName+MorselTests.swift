@testable import CoreMorsel
import Foundation
import Testing

struct NotificationNameMorselTests {
  @Test func didReceiveMorselColorRawValue() async throws {
    #expect(Notification.Name.didReceiveMorselColor.rawValue == "didReceiveMorselColor")
  }
}
