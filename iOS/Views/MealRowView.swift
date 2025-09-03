import CoreMorsel
import SwiftUI
import SwiftData

struct MealRowView: View {
  var entry: FoodEntry
  var onDelete: (() -> Void)? = nil
  var onToggle: (() -> Void)? = nil

  @EnvironmentObject private var appSettings: AppSettings

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: entry.isForMorsel ? "face.smiling.fill" : "person.fill")
        .font(.title3) // slightly larger than footnote/body
        .foregroundStyle(appSettings.morselColor)

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
    .contextMenu {
      Button {
        onToggle?()
      } label: {
        let label = entry.isForMorsel ? "Change to \"For Me\"" : "Change to \"For Morsel\""
        Label(label, systemImage: "arrow.left.arrow.right")
      }

      Button(role: .destructive) {
        onDelete?()
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

#Preview {
  MealRowView(entry: FoodEntry(name: "Pasta Bolognese", timestamp: .now)) {
    // delete action
  } onToggle: {
    // toggle action
  }
    .padding()
    .environmentObject(AppSettings.shared)
    .modelContainer(for: FoodEntry.self, inMemory: true)
}

