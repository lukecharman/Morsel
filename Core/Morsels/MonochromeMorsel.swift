import SwiftUI

struct MonochromeMorsel: View {
  var width: CGFloat
  var color: Color = .white

  private var height: CGFloat { width * 0.74 }
  private var eyeSize: CGFloat { width * 0.116 }
  private var eyeSpacing: CGFloat { width * 0.14 }
  private var eyeOffsetY: CGFloat { height * 0.25 }
  private var mouthWidth: CGFloat { width * 0.28 }
  private var mouthHeight: CGFloat { height * 0.125 }
  private var mouthOffsetY: CGFloat { height * 0.38 }

  private var topCorner: CGFloat { width * 0.74 }
  private var bottomCorner: CGFloat { width * 0.37 }

  @Environment(\.isLuminanceReduced) var isLuminanceReduced

  var body: some View {
    face
      .widgetAccentable()
      .mask {
        ZStack {
          face
          facialFeatures
            .blendMode(.destinationOut)
        }
      }
      .drawingGroup()
  }

  var face: some View {
    UnevenRoundedRectangle(
      cornerRadii: .init(
        topLeading: topCorner,
        bottomLeading: bottomCorner,
        bottomTrailing: bottomCorner,
        topTrailing: topCorner
      ),
      style: .continuous
    )
    .fill(
      isLuminanceReduced ? color.opacity(0.75) : color
    )
    .frame(
      width: width,
      height: height
    )
  }

  var facialFeatures: some View {
    VStack(spacing: height * 0.1) {
      eyes
        .padding(.top, height * 0.03)
      mouth
      Spacer()
    }
    .frame(height: height)
    .frame(maxHeight: .infinity, alignment: .center)
  }

  var eyes: some View {
    HStack(spacing: eyeSpacing) {
      Circle()
        .fill(.black)
        .frame(width: eyeSize, height: eyeSize)
      Circle()
        .fill(.black)
        .frame(width: eyeSize, height: eyeSize)
    }
    .offset(y: eyeOffsetY)
  }

  var mouth: some View {
    UnevenRoundedRectangle(
      cornerRadii: .init(
        topLeading: mouthHeight * 2,
        bottomLeading: mouthHeight * 6,
        bottomTrailing: mouthHeight * 6,
        topTrailing: mouthHeight * 2
      ),
      style: .continuous
    )
    .fill(.black)
    .frame(width: mouthWidth, height: mouthHeight)
    .offset(y: mouthOffsetY)
  }
}
