import SwiftUI

struct GradientColors {
  static func gradientColors(colorScheme: ColorScheme) -> [Color] {
    if colorScheme == .dark {
      return [
        Color.purple.opacity(0.2),
        Color.indigo.opacity(0.15),
        Color(.systemBackground)
      ]
    } else {
      return [
        Color.blue.opacity(0.1),
        Color.cyan.opacity(0.1),
        Color(.systemBackground)
      ]
    }
  }
}
