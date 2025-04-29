import SwiftUI

struct FABButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 1.15 : 1)
      .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
      .opacity(1)
  }
}

struct FAB: View {
  let systemImage: String
  let action: () -> Void

  var body: some View {
    Button(action: {
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      action()
    }) {
      ZStack {
        Circle()
          .fill(Color.accentColor)
          .frame(width: 56, height: 56)
          .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)

        Image(systemName: systemImage)
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.white)
      }
    }
    .buttonStyle(FABButtonStyle())
    .padding(.bottom, 24)
  }
}
