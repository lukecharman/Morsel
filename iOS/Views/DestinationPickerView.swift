import CoreMorsel
import SwiftUI

struct DestinationPickerView: View {
  var onPick: (Bool) -> Void
  var onCancel: () -> Void
  var onDrag: (CGFloat) -> Void = { _ in }

  @GestureState private var dragOffset: CGSize = .zero
  @EnvironmentObject private var appSettings: AppSettings

  @State private var lastHapticBucket: Int = 0
  @State private var wiggleOffset: CGFloat = 0
  @State private var showWiggle = true
  @State private var hasUserInteracted = false
  @State private var wiggleTimer: Timer?
  @State private var snackPrompt: String = Self.randomSnackPrompt

  private let threshold: CGFloat = 80

  var body: some View {
    GeometryReader { geo in
      let dragX = dragOffset.width
      let draggedFarEnoughLeft = dragX < -threshold
      let draggedFarEnoughRight = dragX > threshold

      ZStack {
        Color.clear
          .ignoresSafeArea()
          .onTapGesture { onCancel() }
        VStack {
          Spacer()
          VStack(spacing: 48) {
            Text(snackPrompt)
              .font(MorselFont.title)
              .foregroundColor(.primary)
              .multilineTextAlignment(.center)

            ZStack {
              // Me icon on the left
              VStack(spacing: 8) {
                Image(systemName: "person.fill")
                  .font(.largeTitle)
                  .foregroundColor(draggedFarEnoughLeft ? appSettings.morselColor : .primary.opacity(0.6))
                Text("Me")
                  .font(MorselFont.heading)
                  .foregroundColor(.primary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.leading, 40)

              // Morsel on the right
              VStack(spacing: 8) {
                Image(systemName: "face.smiling.fill")
                  .font(.largeTitle)
                  .foregroundColor(draggedFarEnoughRight ? appSettings.morselColor : .primary.opacity(0.6))
                Text("Morsel")
                  .font(MorselFont.heading)
                  .foregroundColor(.primary)
              }
              .frame(maxWidth: .infinity, alignment: .trailing)
              .padding(.trailing, 40)

              // The draggable plate
              Circle()
                .glass(in: Circle())
                .frame(width: 64, height: 64)
                .overlay(
                  Image(systemName: "fork.knife")
                    .foregroundColor(.primary)
                )
                .offset(x: dragX + (showWiggle ? wiggleOffset : 0))
                .gesture(
                  DragGesture(minimumDistance: 0)
                    .updating($dragOffset) { value, state, _ in
                      state = value.translation
                      
                      // Stop wiggle animation immediately when user touches the handle
                      if showWiggle {
                        withAnimation(.easeOut(duration: 0.2)) {
                          showWiggle = false
                          wiggleOffset = 0
                        }
                      }
                      
                      let normalised = max(-1, min(1, value.translation.width / threshold))
                      onDrag(normalised)

                      let bucketSize: CGFloat = 6
                      let bucket = Int(value.translation.width / bucketSize)
                      if bucket != lastHapticBucket {
                        lastHapticBucket = bucket
                        let level = min(5, Int(abs(normalised) * 6))
                        Haptics.trigger(.level(level))
                      }
                    }
                    .onEnded { value in
                      if value.translation.width < -threshold {
                        onPick(false) // for me
                        Haptics.trigger(.success)
                      } else if value.translation.width > threshold {
                        onPick(true) // for morsel
                        Haptics.trigger(.success)
                      }
                      onDrag(0)
                      lastHapticBucket = 0
                    }
                )
                .animation(.spring(), value: dragX)
            }

            Button("Cancel") {
              onCancel()
            }
            .font(MorselFont.body)
            .foregroundColor(.primary.opacity(0.85))
          }
          .padding()
          .padding(.bottom, 56)
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
      .ignoresSafeArea()
    }
    .onAppear {
      Analytics.track(ScreenViewDestinationPicker())
      
      // Start the wiggle animation to indicate the handle can be dragged
      // Start from left position and animate to right, then autoreverses
      wiggleOffset = -15
      withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
        wiggleOffset = 15
      }
      
      // Stop wiggle after 3 seconds if user hasn't interacted
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        withAnimation(.easeOut(duration: 0.3)) {
          showWiggle = false
          wiggleOffset = 0
        }
      }
    }
  }

  static var randomSnackPrompt: String {
    [
      "So… was that snack meant for you, or me?",
      "Be honest — are you logging it, or offering it?",
      "Snack time: yours or Morsel’s?",
      "Who’s actually getting this one then?",
      "Logging calories, or feeding the beast?",
      "Snack entered... snack surrendered?",
      "Do you plan to eat it, or donate it to me?",
      "Morsel senses a treat — intended target?",
      "Sacrifice accepted… unless you’re keeping it?",
      "Is this for your belly, or my database?",
      "Snack detected. Snack redirected?",
      "Tell me — does this go to you or your faithful Morsel?",
      "Food input confirmed. Ownership uncertain.",
      "Claim it, or let me gobble it down?",
      "Snack logged... but who gets first bite?",
      "Are we recording nutrition or enacting ritual sacrifice?",
      "Who feasts: human or mascot?",
      "Was that snack a confession… or a gift?",
      "For you, or for Morsel?",
      "Snack spotted. Mouth: yours or mine?"
    ].randomElement() ?? "Who was the snack for?"
  }
}
