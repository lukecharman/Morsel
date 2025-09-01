import CoreMorsel
import SwiftUI

struct EmptyStateView: View {
  @Environment(\.colorScheme) private var colorScheme

  @EnvironmentObject var appSettings: AppSettings

  let shouldBlurBackground: Bool
  let shouldHideBackground: Bool
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
          .foregroundColor(appSettings.morselColor)
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
      .scaleEffect(shouldBlurBackground || shouldHideBackground ? 0.98 : 1)
      .opacity(shouldHideBackground ? 0.05 : 1)
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .ignoresSafeArea(.keyboard)
    .onAppear {
      Analytics.track(ScreenViewEmptyState())
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

