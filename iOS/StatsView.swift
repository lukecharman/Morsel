import SwiftUI

struct StatsView: View {
  let statsModel: StatsModel

  var body: some View {
    ScrollView {
      LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
      ], spacing: 16) {
        StatCard(title: "Total Meals", value: "\(statsModel.totalEntries)", icon: "fork.knife")
        StatCard(title: "For Morsel", value: "\(statsModel.totalEntriesForMorsel)", icon: "face.smiling")
        StatCard(title: "For Me", value: "\(statsModel.totalEntriesForMe)", icon: "person.fill")
        StatCard(title: "Current Streak", value: "\(statsModel.currentStreak)", icon: "flame.fill")
        StatCard(title: "Longest Streak", value: "\(statsModel.longestStreak)", icon: "trophy.fill")
      }
      .padding()
    }
    .mask(
      LinearGradient(
        gradient: Gradient(stops: [
          .init(color: .clear, location: 0),
          .init(color: .black, location: 0.01),
          .init(color: .black, location: 0.98),
          .init(color: .clear, location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let icon: String

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: icon)
        .font(.largeTitle)
        .foregroundColor(.accentColor)
        .padding(8)
        .background(.ultraThinMaterial, in: Circle())

      Text(value)
        .font(.title.bold())

      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
    .shadow(radius: 4, y: 2)
  }
}



#Preview {
  StatsView(statsModel: StatsModel(modelContainer: .sharedContainer))
    .background(Color(.systemGroupedBackground))
}
