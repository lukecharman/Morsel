import CoreMorsel
import SwiftUI

struct LockedOverlayView: View {
  let title: String
  let message: String

  var body: some View {
    VStack(spacing: 12) {
      Text(title)
        .font(MorselFont.heading)
      Text(message)
        .font(MorselFont.body)
        .multilineTextAlignment(.center)
    }
    .padding()
    .frame(maxWidth: .infinity)
    .background(.ultraThinMaterial)
    .cornerRadius(12)
    .padding()
  }
}
