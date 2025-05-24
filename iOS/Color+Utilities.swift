import SwiftUI
import UIKit

extension Color {
  static func darkened(from color: Color, percentage: CGFloat = 0.75) -> Color {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    guard UIColor(color).getHue(
      &hue,
      saturation: &saturation,
      brightness: &brightness,
      alpha: &alpha
    ) else {
      return Color(color)
    }

    return Color(
      UIColor(
        hue: hue,
        saturation: saturation,
        brightness: max(brightness * (1 - percentage), 0),
        alpha: alpha
      )
    )
  }
}
