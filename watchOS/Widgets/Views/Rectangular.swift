import SwiftUI
import WidgetKit

struct QuickLogRectangularView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    HStack(spacing: 12) {
      MonochromeMorsel(width: 50)
        .widgetAccentable()
      VStack(alignment: .leading) {
        Text("Morsel")
          .font(.headline)
          .fontDesign(.rounded)
          .widgetAccentable()
        Text("Today: \(entry.mealCount)")
          .font(.caption2)
          .fontDesign(.rounded)
          .foregroundColor(.secondary)
      }
      
    }
    .widgetURL(URL(string: "morsel://add")!)
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

#Preview(as: .accessoryRectangular, widget: {
  QuickLogWithCountWidget()
}, timeline: {
  QuickLogWithCountEntry(date: Date(), mealCount: 0)
  QuickLogWithCountEntry(date: Date().addingTimeInterval(200), mealCount: 1)
  QuickLogWithCountEntry(date: Date().addingTimeInterval(400), mealCount: 2)
})

#Preview(as: .accessoryRectangular, widget: {
  QuickLogNoCountWidget()
}, timeline: {
  QuickLogNoCountEntry(date: Date())
})

