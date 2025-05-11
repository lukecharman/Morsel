import SwiftUI

struct EmptyStateView: View {
  @Environment(\.colorScheme) private var colorScheme

  let shouldBlurBackground: Bool

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "fork.knife.circle")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
        .foregroundColor(.accentColor)
        .opacity(0.4)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

      (
        Text("Still waiting on your ")
          .font(MorselFont.title)
          .fontWeight(.medium)
      +
        Text("first bite")
          .font(MorselFont.title)
          .fontWeight(.bold)
      +
        Text("...")
          .font(MorselFont.title)
          .fontWeight(.medium)
      )
      .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
      .multilineTextAlignment(.center)

      Text("The first snack is the hardest.\nGive Morsel a tap to begin.")
        .font(MorselFont.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

      Text("↓")
        .font(MorselFont.title)
        .fontWeight(.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        colors: GradientColors.gradientColors(colorScheme: colorScheme),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .opacity(shouldBlurBackground ? 0.06 : 1)
    .scaleEffect(shouldBlurBackground ? CGSize(width: 0.97, height: 0.97) : CGSize(width: 1.0, height: 1.0))
    .onAppear {
      Analytics.track(ScreenViewEmptyState())
    }
  }
}

