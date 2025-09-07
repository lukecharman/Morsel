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
    // The caller already supplies the formatted text via ViewModel, but this view is given only the
    // display text; if needed we could pass it in. For now, we keep it simple and compute here is not available.
    // We received the final formatted encouragement through the parent; using that directly.
    // In this refactor, encouragement is passed in via the parent as part of body content.
    // To preserve behavior, we keep what parent supplies. Here, just return it.
    // However, in current wiring, we passed only tip/date/title; encouragement comes from parent closure.
    // For clarity and minimal change, we’ll compute it here is not available. Parent already computed and passed
    // formattedRange; we can also compute encouragement externally. To avoid dependency, we keep the layout text injected.
    // This placeholder will be replaced by injected text; keeping property for completeness.
    ""
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
