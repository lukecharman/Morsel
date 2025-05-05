import SwiftUI

struct StatsView: View {
  var body: some View {
    ScrollView {
      LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
      ], spacing: 16) {
        StatCard(title: "Total Meals", value: "162", icon: "fork.knife")
        StatCard(title: "For Morsel", value: "88", icon: "face.smiling")
        StatCard(title: "For Me", value: "74", icon: "person.fill")
        StatCard(title: "Longest Streak", value: "5d", icon: "flame.fill")
      }
      .padding()
    }
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
  StatsView()
    .background(Color(.systemGroupedBackground))
}
