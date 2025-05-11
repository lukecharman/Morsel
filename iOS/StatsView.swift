import SwiftUI

struct StatsView: View {
  let statsModel: StatsModel

  var body: some View {
    ScrollView {
      LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
      ], spacing: 16) {
        CardView(title: "Total Meals", value: "\(statsModel.totalEntries)", icon: "fork.knife")
        CardView(title: "Cravings Crushed", value: "\(statsModel.totalEntriesForMorsel)", icon: "face.smiling")
        CardView(title: "Mindful Munchies", value: "\(statsModel.totalEntriesForMe)", icon: "person.fill")
        CardView(title: "Current Streak", value: "\(statsModel.currentStreak)", icon: "flame.fill")
        CardView(title: "Longest Streak", value: "\(statsModel.longestStreak)", icon: "trophy.fill")
        CardView(title: "% For Morsel", value: "\(statsModel.averageMorselPercentagePerDay)", icon: "percent")
      }
      .safeAreaInset(edge: .top) {
        Spacer().frame(height: 16)
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
  StatsView(statsModel: StatsModel(modelContainer: .sharedContainer))
    .background(Color(.systemGroupedBackground))
}
