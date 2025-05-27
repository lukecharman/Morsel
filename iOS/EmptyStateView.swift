import SwiftUI

struct EmptyStateView: View {
  @Environment(\.colorScheme) private var colorScheme

  let shouldBlurBackground: Bool
  let isFirstLaunch: Bool
  let onTap: () -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      BackgroundGradientView()
      VStack(spacing: 24) {
        Image(systemName: isFirstLaunch ? "sparkles" : "fork.knife.circle")
          .resizable()
          .scaledToFit()
          .frame(width: 80, height: 80)
          .foregroundColor(.accentColor)
          .opacity(0.4)
          .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

        (
          Text(isFirstLaunch ? "Welcome to " : "Still waiting on your ")
            .font(MorselFont.title)
            .fontWeight(.medium)
          +
          Text(isFirstLaunch ? "Morsel" : "first bite")
            .font(MorselFont.title)
            .fontWeight(.bold)
          +
          Text("...")
            .font(MorselFont.title)
            .fontWeight(.medium)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
        .multilineTextAlignment(.center)

        Text(isFirstLaunch
          ? "Track what you eat and what you resist.\nGive Morsel a tap to begin."
          : "The first snack is the hardest.\nGive Morsel a tap to begin.")
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
      .opacity(shouldBlurBackground ? 0.06 : 1)
      .scaleEffect(shouldBlurBackground ? CGSize(width: 0.97, height: 0.97) : CGSize(width: 1.0, height: 1.0), anchor: .top)
      .onAppear {
        Analytics.track(ScreenViewEmptyState())
      }
    }
    .simultaneousGesture(
      TapGesture()
        .onEnded{ _ in
          if shouldBlurBackground {
            onTap()
          }
        }
    )
    .simultaneousGesture(
      DragGesture()
        .onChanged { value in
          if shouldBlurBackground && value.translation.height > 0 {
            onTap()
          }
        }
    )
  }
}

