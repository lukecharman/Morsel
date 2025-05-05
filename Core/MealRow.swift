import SwiftUI
import SwiftData

struct MealRow: View {
  var entry: FoodEntry

  var body: some View {
    HStack(spacing: 16) {
      Text(entry.name)
        .font(MorselFont.heading)
        .foregroundColor(entry.isForMorsel ? .primary.opacity(0.5) : .primary)
        .opacity(entry.isForMorsel ? 0.5 : 1)
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
        .allowsTightening(true)
        .allowsHitTesting(false)
      Text(entry.timestamp, format: .dateTime.hour().minute())
        .font(MorselFont.small)
        .foregroundColor(.secondary)
        .layoutPriority(1)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .contentShape(Rectangle())
  }
}

#Preview {
  MealRow(entry: FoodEntry(name: "Pasta Bolognese", timestamp: .now))
    .padding()
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
