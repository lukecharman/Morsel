import CoreMorsel
import SwiftUI

struct StatsView: View {
  let statsModel: StatsModel
  let onRequestDigest: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        Spacer().frame(height: 16)
        CardView(
          title: "The Digest",
          value: "",
          icon: "fork.knife",
          description: nil,
          isFirst: true,
        ) {
          onRequestDigest()
        }
        CardView(
          title: "Total Meals",
          value: "\(statsModel.totalEntries)",
          icon: "fork.knife",
          description: "The total number of meals you've logged."
        )
        CardView(
          title: "Cravings Crushed",
          value: "\(statsModel.totalEntriesForMorsel)",
          icon: "face.smiling",
          description: "How many times you've resisted cravings and fed Morsel instead."
        )
        CardView(
          title: "Mindful Munchies",
          value: "\(statsModel.totalEntriesForMe)",
          icon: "person.fill",
          description: "Meals you’ve logged that you actually ate."
        )
        CardView(
          title: "Current Streak",
          value: "\(statsModel.currentStreak)",
          icon: "flame.fill",
          description: "Your current streak of consecutive days with at least one logged meal."
        )
        CardView(
          title: "Longest Streak",
          value: "\(statsModel.longestStreak)",
          icon: "trophy.fill",
          description: "The longest streak you’ve maintained without breaking the habit."
        )
        CardView(
          title: "% For Morsel",
          value: "\(statsModel.averageMorselPercentagePerDay)",
          icon: "percent",
          description: "The average daily percentage of meals you fed to Morsel.",
          isLast: true
        )
      }
      .padding(.horizontal, 16)
    }
    .mask(
      LinearGradient(
        gradient: Gradient(stops: [
          .init(color: .clear, location: 0),
          .init(color: .black, location: 0.01),
          .init(color: .black, location: 0.925),
          .init(color: .clear, location: 0.955),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .onAppear {
      Analytics.track(ScreenViewStats())
    }
  }
}

#Preview {
  StatsView(
    statsModel: StatsModel(modelContainer: .morsel),
    onRequestDigest: {}
  )
  .background(Color(.systemGroupedBackground))
}
