import SwiftGlass
import SwiftUI

public enum GlassType {
  case clear
  case regular

  @available(iOS 26, watchOS 26, *)
  var glass: Glass {
    switch self {
    case .clear: Glass.regular
    case .regular: Glass.regular
    }
  }
}

public extension View {
  @ViewBuilder
  func glass<ShapeType: Shape>(
    _ variant: GlassType = .regular,
    in shape: ShapeType? = nil
  ) -> some View {
    if #available(iOS 26, watchOS 26, *) {
      if let shape {
        self.glassEffect(variant.glass, in: shape)
      } else {
        self.glassEffect(variant.glass)
      }
    } else {
      self.glass(displayMode: .automatic)
    }
  }

  func glass(
    _ variant: GlassType = .regular
  ) -> some View {
    if #available(iOS 26, watchOS 26, *) {
      return self.glassEffect(variant.glass, in: DefaultGlassEffectShape())
    } else {
      return self.glass(displayMode: .automatic)
    }
  }
}
