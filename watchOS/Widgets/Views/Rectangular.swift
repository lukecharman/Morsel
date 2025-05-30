import SwiftUI
import WidgetKit

struct QuickLogRectangularView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    HStack(spacing: 12) {
      MonochromeMorsel(width: 30)
        .widgetAccentable()
      VStack(alignment: .leading) {
        Text("Add Morsel")
          .font(.headline)
          .widgetAccentable()
        Text("Today: \(entry.mealCount)")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .widgetURL(URL(string: "morsel://add")!)
    .containerBackground(.fill.tertiary, for: .widget)
  }
}
