import CoreMorsel
import SwiftUI

struct DigestEmptyStateView: View {
  @EnvironmentObject var appSettings: AppSettings

  var body: some View {
    ZStack {
      BackgroundGradientView()
      VStack(spacing: 24) {
        Image(systemName: "chart.bar.doc.horizontal")
          .resizable()
          .scaledToFit()
          .frame(width: 80, height: 80)
          .foregroundColor(appSettings.morselColor)
          .opacity(0.4)
          .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

        Text(digestText)
          .multilineTextAlignment(.center)
          .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

        Text("Log a few bites and victories.\nCome back here to see how your week is shaping up.")
          .font(MorselFont.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
          .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      //Analytics.track(ScreenViewEmptyState(name: "DigestEmpty"))
    }
  }

  var digestText: AttributedString {
    var leading = AttributedString("Your weekly digest")
    leading.font = MorselFont.title.weight(.bold)

    var middle = AttributedString(" is waiting")
    middle.font = MorselFont.title.weight(.medium)

    var dots = AttributedString("...")
    dots.font = MorselFont.title.weight(.medium)

    return leading + middle + dots
  }
}

