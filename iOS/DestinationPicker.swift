import SwiftUI

struct DestinationPicker: View {
  var onPick: (Bool) -> Void
  var onCancel: () -> Void

  @GestureState private var dragOffset: CGSize = .zero

  private let threshold: CGFloat = 80

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width
      let dragX = dragOffset.width
      let draggedFarEnoughLeft = dragX < -threshold
      let draggedFarEnoughRight = dragX > threshold

      ZStack {
        // Background fade
        Color.black.opacity(0.5)
          .ignoresSafeArea()
          .onTapGesture { onCancel() }

        VStack(spacing: 48) {
          Text("Who was the snack for?")
            .font(MorselFont.title)
            .foregroundColor(.white)

          ZStack {
            // Me icon on the left
            VStack(spacing: 8) {
              Image(systemName: "person.fill")
                .font(.largeTitle)
                .foregroundColor(draggedFarEnoughLeft ? .accentColor : .white.opacity(0.6))
              Text("Me")
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 40)

            // Morsel on the right
            VStack(spacing: 8) {
              Image(systemName: "face.smiling.fill")
                .font(.largeTitle)
                .foregroundColor(draggedFarEnoughRight ? .accentColor : .white.opacity(0.6))
              Text("Morsel")
                .foregroundColor(.white)
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
                  }
                  .onEnded { value in
                    if value.translation.width < -threshold {
                      onPick(false) // for me
                    } else if value.translation.width > threshold {
                      onPick(true) // for morsel
                    }
                  }
              )
              .animation(.spring(), value: dragX)
          }

          Button("Cancel") {
            onCancel()
          }
          .foregroundColor(.white.opacity(0.6))
        }
        .padding()
      }
    }
  }
}
