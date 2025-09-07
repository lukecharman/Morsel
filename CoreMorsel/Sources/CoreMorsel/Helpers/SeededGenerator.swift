import Foundation

public struct SeededGenerator: RandomNumberGenerator {
  public init(seed: Int) {
    self.state = UInt64(seed)
  }

  private var state: UInt64

  public mutating func next() -> UInt64 {
    state = state &* 6364136223846793005 &+ 1
    return state
  }
}
