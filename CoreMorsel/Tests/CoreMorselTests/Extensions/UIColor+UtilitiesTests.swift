@testable import CoreMorsel
import UIKit
import Testing

struct UIColorUtilitiesTests {
  @Test func rgbaReturnsComponents() async throws {
    let color = UIColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 0.5)
    let components = color.rgba
    #expect(components[0] == 0.25)
    #expect(components[1] == 0.5)
    #expect(components[2] == 0.75)
    #expect(components[3] == 0.5)
  }
}
