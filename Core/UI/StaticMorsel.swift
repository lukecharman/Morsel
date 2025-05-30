import SwiftUI

struct StaticMorsel: View {
  var color: Color = .blue

  var body: some View {
    ZStack(alignment: .bottom) {
      face
      facialFeatures
        .blendMode(.destinationOut)
    }
    .padding()
  }

  var face: some View {
    UnevenRoundedRectangle(
      cornerRadii: .init(
        topLeading: 64,
        bottomLeading: 32,
        bottomTrailing: 32,
        topTrailing: 64
      ),
      style: .continuous
    )
    .fill(color)
    .frame(
      width: 86,
      height: 64
    )
  }

  var facialFeatures: some View {
    VStack {
      eyes
      mouth
      Spacer()
    }
  }

  var eyes: some View {
    HStack(spacing: 12) {
      Circle()
        .frame(width: 10, height: 10)
      Circle()
        .frame(width: 10, height: 10)
    }
    .offset(y: 16)
  }

  var mouth: some View {
    ZStack {
      UnevenRoundedRectangle(
        cornerRadii: .init(
          topLeading: 16,
          bottomLeading: 48,
          bottomTrailing: 48,
          topTrailing: 16
        ),
        style: .continuous
      )
      .frame(width: 24, height: 8)
      .offset(y: 24)
    }
  }
}
