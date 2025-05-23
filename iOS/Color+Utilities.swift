import UIKit

struct ColorUtilities {
  static func mouthColor(from color: UIColor, percentage: CGFloat = 0.75) -> UIColor {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
      return color
    }

    let adjustedBrightness = max(brightness * (1 - percentage), 0)
    return UIColor(hue: hue, saturation: saturation, brightness: adjustedBrightness, alpha: alpha)
  }
}
