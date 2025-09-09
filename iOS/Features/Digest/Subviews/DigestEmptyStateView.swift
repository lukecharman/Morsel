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

        (
          Text("Your weekly digest")
            .font(MorselFont.title)
            .fontWeight(.bold)
          +
          Text(" is waiting")
            .font(MorselFont.title)
            .fontWeight(.medium)
          +
          Text("...")
            .font(MorselFont.title)
            .fontWeight(.medium)
        )
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
}

