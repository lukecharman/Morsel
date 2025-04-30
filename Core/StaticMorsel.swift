import SwiftUI

struct StaticMorsel: View {
  var body: some View {
    ZStack(alignment: .bottom) {
      face
        .overlay(facialFeatures)
        .shadow(radius: 10)
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
    .fill(Color.accentColor)
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
        .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
        .frame(width: 10, height: 10)
        .shadow(radius: 4)
      Circle()
        .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
        .frame(width: 10, height: 10)
        .shadow(radius: 4)
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
      .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
      .frame(width: 24, height: 8)
      .offset(y: 24)
      .shadow(radius: 10)
    }
  }
}
