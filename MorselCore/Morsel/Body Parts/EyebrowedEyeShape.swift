import SwiftUI

struct EyebrowedEyeShape: Shape {
  var eyebrowAmount: CGFloat // 0 = circle, 1 = flat segment
  var angle: Angle // angle of flat segment

  var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get { AnimatablePair(eyebrowAmount, CGFloat(angle.degrees)) }
    set {
      eyebrowAmount = newValue.first
      angle = .degrees(Double(newValue.second))
    }
  }

  func path(in rect: CGRect) -> Path {
    let clamped = min(max(eyebrowAmount, 0), 1)
    let radius = min(rect.width, rect.height) / 2
    let center = CGPoint(x: rect.midX, y: rect.midY)

    var path = Path()

    if clamped == 0 {
      path.addEllipse(in: CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
      ))
      return path
    }

    let delta = 90.0 * (1 - clamped)
    let startAngle = angle + .degrees(delta)
    let endAngle = angle + .degrees(180 - delta)

    path.addArc(
      center: center,
      radius: radius,
      startAngle: startAngle,
      endAngle: endAngle,
      clockwise: true
    )

    // Flat line to close the arc
    let left = CGPoint(
      x: center.x + radius * cos(CGFloat(endAngle.radians)),
      y: center.y + radius * sin(CGFloat(endAngle.radians))
    )
    let right = CGPoint(
      x: center.x + radius * cos(CGFloat(startAngle.radians)),
      y: center.y + radius * sin(CGFloat(startAngle.radians))
    )
    path.addLine(to: right)
    path.addLine(to: left)

    path.closeSubpath()
    return path
  }
}
