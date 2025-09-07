import SwiftUI

struct GlassCapsuleBackground: View {
  var body: some View {
    Capsule(style: .continuous)
      .fill(Color.clear)
      .glassEffect(.clear, in: Capsule(style: .continuous))
  }
}

private struct GlassCapsuleBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    content.background(GlassCapsuleBackground())
  }
}

extension View {
  func glassCapsuleBackground() -> some View {
    self.modifier(GlassCapsuleBackgroundModifier())
  }
}
