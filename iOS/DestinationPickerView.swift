import SwiftUI

struct DestinationPickerView: View {
  var onPick: (Bool) -> Void
  var onCancel: () -> Void
  var onDrag: (CGFloat) -> Void = { _ in }

  @GestureState private var dragOffset: CGSize = .zero
  @EnvironmentObject private var appSettings: AppSettings
  @State private var lastHapticBucket: Int = 0

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
            Text("Who was the snack for?")
              .font(MorselFont.title)
              .foregroundColor(.primary)

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
                .fill(.ultraThinMaterial)
                .frame(width: 64, height: 64)
                .overlay(
                  Image(systemName: "fork.knife")
                    .foregroundColor(.primary)
                )
                .offset(x: dragX)
                .gesture(
                  DragGesture()
                    .updating($dragOffset) { value, state, _ in
                      state = value.translation
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
    }
  }
}
