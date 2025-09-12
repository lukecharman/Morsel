import CoreMorsel
import SwiftUI

struct DigestPageView: View {
  @EnvironmentObject var appSettings: AppSettings

  let digest: DigestModel
  let title: String
  let availabilityState: DigestAvailabilityState
  let blurRadius: Double?
  let shouldAnimateUnblur: Bool
  let onWillAnimate: () -> Void
  let onTriggerUnblur: () -> Void
  let unlockMessage: String
  let formattedRange: String

  var body: some View {
    ZStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Spacer().frame(height: 44)
          DigestHeaderView(title: title, dateRange: formattedRange)
          DigestStatsView(digest: digest)
          VStack(alignment: .leading, spacing: 8) {
            Text("How you did")
              .font(MorselFont.heading)
            Text(encouragementText)
              .font(MorselFont.body)
          }
          DigestTipView(tipText: digest.tip.rawValue, accent: appSettings.morselColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .blur(radius: contentBlur)
        .allowsHitTesting(availabilityState != .locked)
        .accessibilityHidden(availabilityState == .locked)
      }
      .disabled(availabilityState == .locked)
      .ignoresSafeArea()
      .onAppear {
        if shouldAnimateUnblur {
          onWillAnimate()
          onTriggerUnblur()
        }
      }

      if availabilityState == .locked {
        LockedOverlayView(
          title: "This week isn't finished yet!",
          message: unlockMessage
        )
      }
    }
  }

  private var encouragementText: String {
    // Simple heuristic until we wire real copy from the ViewModel.
    // Derives a friendly message from digest stats.
    let meals = digest.mealsLogged
    let resisted = digest.cravingsResisted
    let gaveIn = digest.cravingsGivenIn

    var parts: [String] = []

    if meals > 0 {
      parts.append("You logged \(meals) \(meals == 1 ? "meal" : "meals").")
    }

    if resisted > 0 {
      parts.append("You resisted \(resisted) \(resisted == 1 ? "craving" : "cravings"). Nice work!")
    }

    if gaveIn > 0 {
      parts.append("You gave in \(gaveIn) \(gaveIn == 1 ? "time" : "times"), and that's okay. Progress isn't linear.")
    }

    if parts.isEmpty {
      return "No activity recorded yet. Come back after logging some meals to see your weekly insights."
    } else {
      return parts.joined(separator: " ")
    }
  }

  private var contentBlur: CGFloat {
    switch availabilityState {
    case .locked:
      return 8
    case .unlockable:
      return CGFloat(blurRadius ?? 8)
    case .unlocked:
      return CGFloat(blurRadius ?? 0)
    }
  }
}
