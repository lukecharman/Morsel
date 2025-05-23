import SwiftUI

struct GradientColors {
  static func gradientColors(colorScheme: ColorScheme) -> [Color] {
    if colorScheme == .dark {
      return [
        Color(ColorUtilities.mouthColor(from: AppSettings.shared.morselColor, percentage: 0.9)),
        Color(ColorUtilities.mouthColor(from: AppSettings.shared.morselColor, percentage: 0.95)),
        Color(.systemBackground)
      ]
    } else {
      return [
        Color(ColorUtilities.mouthColor(from: AppSettings.shared.morselColor, percentage: 0.15)).opacity(0.2),
        Color(ColorUtilities.mouthColor(from: AppSettings.shared.morselColor, percentage: 0.1)).opacity(0.2),
        Color(.systemBackground)
      ]
    }
  }
}
