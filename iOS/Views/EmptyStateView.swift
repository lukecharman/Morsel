import CoreMorsel
import SwiftUI

struct EmptyStateView: View {
  @Environment(\.colorScheme) private var colorScheme

  @EnvironmentObject var appSettings: AppSettings

  let shouldBlurBackground: Bool
  let shouldHideBackground: Bool
  let isFirstLaunch: Bool
  let onTap: () -> Void

  // Animation state for the arrow
  @State private var startArrowAnimation = false
  @State private var arrowOffset: CGFloat = 0
  @State private var hasScheduledArrowTimer = false
  @State private var isAnimatingArrow = false

  var body: some View {
    ZStack(alignment: .bottom) {
      BackgroundGradientView()
      VStack(spacing: 24) {
        Image(systemName: isFirstLaunch ? "sparkles" : "fork.knife")
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
          .offset(y: arrowOffset)
          .onChange(of: startArrowAnimation) { _, newValue in
            guard newValue, !isAnimatingArrow else { return }
            isAnimatingArrow = true
            // Run a controlled loop with a small pause between cycles
            Task { @MainActor in
              while startArrowAnimation {
                withAnimation(.easeInOut(duration: 0.9)) {
                  arrowOffset = 8 // move down gently
                }
                try? await Task.sleep(nanoseconds: 900_000_000) // match animation duration

                withAnimation(.easeInOut(duration: 0.9)) {
                  arrowOffset = 0 // return to original
                }
                try? await Task.sleep(nanoseconds: 900_000_000) // match animation duration

                // Little gap between each oscillation
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 0.35s pause
              }
              isAnimatingArrow = false
            }
          }
      }
      .scaleEffect(shouldBlurBackground || shouldHideBackground ? 0.98 : 1)
      .opacity(shouldHideBackground ? 0.05 : 1)
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .ignoresSafeArea(.keyboard)
    .onAppear {
      Analytics.track(ScreenViewEmptyState())

      // Schedule the arrow animation to start after 3 seconds, once.
      if !hasScheduledArrowTimer {
        hasScheduledArrowTimer = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
          startArrowAnimation = true
        }
      }
    }
    .onDisappear {
      // Reset state so it can start again on next appearance
      startArrowAnimation = false
      arrowOffset = 0
      hasScheduledArrowTimer = false
      isAnimatingArrow = false
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
