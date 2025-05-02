import SwiftUI
import SwiftData

struct MealRow: View {
  var entry: FoodEntry

  var body: some View {
    HStack(spacing: 4) {
      Text(entry.name)
        .font(.title3.weight(.semibold))
        .foregroundColor(.primary)
      Spacer()
      Text(entry.timestamp, format: .dateTime.hour().minute())
        .font(.footnote)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  MealRow(entry: FoodEntry(name: "Pasta Bolognese", timestamp: .now))
    .padding()
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
