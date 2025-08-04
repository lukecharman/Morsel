import Foundation

extension CGFloat {
  static func lerp(from: CGFloat, to: CGFloat, by amount: CGFloat) -> CGFloat {
    from + (to - from) * amount
  }
}
