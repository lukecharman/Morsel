@testable import CoreMorsel
import UIKit
import Testing

struct UIColorUtilitiesTests {
  @Test func returnsRGBAComponents() async throws {
    let color = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
    let components = color.rgba
    #expect(components.count == 4)
    #expect(abs(components[0] - 0.2) < 0.0001)
    #expect(abs(components[1] - 0.4) < 0.0001)
    #expect(abs(components[2] - 0.6) < 0.0001)
    #expect(abs(components[3] - 0.8) < 0.0001)
  }
}
