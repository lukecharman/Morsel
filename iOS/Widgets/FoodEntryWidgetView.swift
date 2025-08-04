import CoreMorsel
import SwiftUI
import WidgetKit

struct FoodEntryWidgetView: View {
  var entry: FoodEntryTimelineEntry

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetFamily) private var widgetFamily

  @EnvironmentObject var appSettings: AppSettings

  var body: some View {
    ZStack {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(
            widgetFamily == .systemSmall
              ? "Today (\(entry.foodEntries.count))"
              : "Today's Morsels (\(entry.foodEntries.count))"
          )
          .font(widgetFamily == .systemSmall ?  MorselFont.widgetTitle : MorselFont.title)
            .foregroundStyle(.primary)
            .padding(.bottom, 8)
            .contentTransition(.numericText())

          if entry.foodEntries.isEmpty {
            Text("Nothin' yet.")
              .font(MorselFont.body)
              .font(.caption)
              .foregroundStyle(.secondary)
          } else {
            switch widgetFamily {
            case .systemSmall:
              column(for: Array(entry.foodEntries.prefix(3)))

            default:
              let entries = Array(entry.foodEntries.prefix(6))
              let firstColumnEntries = entries.indices
                .filter { $0 % 2 == 0 }
                .map { entries[$0] }

              let secondColumnEntries = entries.indices
                .filter { $0 % 2 != 0 }
                .map { entries[$0] }

              HStack(alignment: .top, spacing: 16) {
                column(for: firstColumnEntries)
                  .frame(maxWidth: .infinity, alignment: .leading)

                column(for: secondColumnEntries)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
          Spacer()
        }
        Spacer()
      }
      GeometryReader { geo in
        Link(destination: URL(string: "morsel://add")!) {
          StaticMorsel(color: entry.morselColor)
        }
        .frame(
          width: widgetFamily == .systemSmall ? 40 : 40,
          height: widgetFamily == .systemSmall ? 40 : 40
        )
        .scaleEffect(
          widgetFamily == .systemSmall ? CGSize(width: 0.6, height: 0.6) : CGSize(width: 0.7, height: 0.7)
        )
        .position(
          x: geo.size.width - (widgetFamily == .systemSmall ? 22 : 36),
          y: geo.size.height - (widgetFamily == .systemSmall ? 18 : 26)
        )
      }
    }
    .ignoresSafeArea()
    .widgetURL(URL(string: "morsel://list")!)
    .containerBackground(for: .widget) {
      Color.black
    }
  }

  func column(for entries: [FoodEntrySnapshot]) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      ForEach(entries, id: \.id) { foodEntry in
        HStack(spacing: 8) {
          Image(systemName: foodEntry.isForMorsel ? "face.smiling.fill" : "person.fill")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(foodEntry.name)
            .font(widgetFamily == .systemSmall ?  MorselFont.widgetBody : MorselFont.body)
            .lineLimit(1)
            .opacity(foodEntry.isForMorsel ? 0.5 : 1)
            .foregroundStyle(.primary)
        }
      }
    }
  }
}

#Preview(as: .systemMedium, widget: {
  FoodEntryWidget()
}, timeline: {
  FoodEntryTimelineEntry(date: .now, foodEntries: [
    FoodEntrySnapshot(name: "Toast")
  ], morselColor: .blue)
  FoodEntryTimelineEntry(date: .now, foodEntries: [
    FoodEntrySnapshot(name: "Toast"),
    FoodEntrySnapshot(name: "Chocolate Bar", isForMorsel: true)
  ], morselColor: .blue)
  FoodEntryTimelineEntry(date: .now, foodEntries: [
    FoodEntrySnapshot(name: "Toast"),
    FoodEntrySnapshot(name: "Chocolate Bar", isForMorsel: true),
    FoodEntrySnapshot(name: "Egg Sandwich"),
    FoodEntrySnapshot(name: "Tomatoes", isForMorsel: true),
    FoodEntrySnapshot(name: "Haribo"),
    FoodEntrySnapshot(name: "Pistachios")
  ], morselColor: .blue)
})
