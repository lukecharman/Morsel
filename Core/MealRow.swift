import SwiftUI
import SwiftData

struct MealRow: View {
  var entry: FoodEntry

  var body: some View {
    HStack(spacing: 16) {
      Text(entry.name)
        .font(MorselFont.heading)
        .foregroundColor(.primary)
        .layoutPriority(1)
      Rectangle()
        .foregroundStyle(
          LinearGradient(
            colors: [.clear, .primary.opacity(0.18)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(height: 1)
      Text(entry.timestamp, format: .dateTime.hour().minute())
        .font(MorselFont.small)
        .foregroundColor(.secondary)
        .layoutPriority(1)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
}

#Preview {
  MealRow(entry: FoodEntry(name: "Pasta Bolognese", timestamp: .now))
    .padding()
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
