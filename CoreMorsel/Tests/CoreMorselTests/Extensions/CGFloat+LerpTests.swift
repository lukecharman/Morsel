@testable import CoreMorsel
import Foundation
import Testing

struct CGFloatLerpTests {
  @Test func returnsStartValueWhenAmountIsZero() async throws {
    let result = CGFloat.lerp(from: 2, to: 10, by: 0)
    #expect(result == 2)
  }

  @Test func returnsEndValueWhenAmountIsOne() async throws {
    let result = CGFloat.lerp(from: 2, to: 10, by: 1)
    #expect(result == 10)
  }

  @Test func interpolatesLinearly() async throws {
    let result = CGFloat.lerp(from: 2, to: 10, by: 0.25)
    #expect(result == 4)
  }

  @Test func allowsExtrapolation() async throws {
    let result = CGFloat.lerp(from: 2, to: 10, by: 1.5)
    #expect(result == 14)
  }
}
