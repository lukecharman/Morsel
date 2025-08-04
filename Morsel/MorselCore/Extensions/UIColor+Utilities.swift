import UIKit

extension UIColor {
  var rgba: [Double] {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return [Double(r), Double(g), Double(b), Double(a)]
  }
}
