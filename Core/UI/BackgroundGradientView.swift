import SwiftUI
import UIKit

struct BackgroundGradientView: View {
  @Environment(\.colorScheme) private var systemColorScheme
  @EnvironmentObject var appSettings: AppSettings

  var body: some View {
    LinearGradient(
      colors: gradientColors(colorScheme: effectiveColorScheme),
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
  
  var effectiveColorScheme: ColorScheme {
    appSettings.appTheme.colorScheme ?? systemColorScheme
  }

  func gradientColors(colorScheme: ColorScheme) -> [Color] {
    if colorScheme == .dark {
#if os(iOS)
      return [
        .darkened(from: appSettings.morselColor, percentage: 0.9),
        .darkened(from: appSettings.morselColor, percentage: 0.95),
        Color(uiColor: .systemBackground)
      ]
#else
      return [
        .darkened(from: appSettings.morselColor, percentage: 0.9),
        .darkened(from: appSettings.morselColor, percentage: 0.95),
        Color(uiColor: .clear)
      ]
#endif
    } else {
#if os(iOS)
      return [
        .darkened(from: appSettings.morselColor, percentage: 0.15).opacity(0.2),
        .darkened(from: appSettings.morselColor, percentage: 0.1).opacity(0.2),
        Color(uiColor: .systemBackground)
      ]
#else
      return [
        .darkened(from: appSettings.morselColor, percentage: 0.9),
        .darkened(from: appSettings.morselColor, percentage: 0.95),
        Color(uiColor: .clear)
      ]
#endif
    }
  }

}
