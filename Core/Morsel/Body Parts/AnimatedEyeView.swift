import SwiftUI

struct AnimatedEyeView: View {
  @Binding var amount: CGFloat
  @Binding var angle: Angle

  var body: some View {
    EyebrowedEyeShape(eyebrowAmount: amount, angle: angle)
      .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
      .animation(.easeInOut(duration: 0.3), value: amount)
  }
}
