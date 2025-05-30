import SwiftUI
import WidgetKit

struct QuickLogCornerView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    VStack {
      Text("\(entry.mealCount)")
        .widgetCurvesContent()
        .widgetLabel("Morsels")
        .widgetAccentable()
        .widgetURL(URL(string: "morsel://add")!)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}

struct QuickLogNoCountCornerView: View {
  var body: some View {
    MonochromeMorsel(width: 28)
      .widgetAccentable()
      .widgetURL(URL(string: "morsel://add")!)
      .containerBackground(.fill.tertiary, for: .widget)
  }
}

#Preview(as: .accessoryCorner, widget: {
  QuickLogWithCountWidget()
}, timeline: {
  QuickLogWithCountEntry(date: Date(), mealCount: 0)
  QuickLogWithCountEntry(date: Date().addingTimeInterval(200), mealCount: 1)
  QuickLogWithCountEntry(date: Date().addingTimeInterval(400), mealCount: 2)
})

#Preview(as: .accessoryCorner, widget: {
  QuickLogNoCountWidget()
}, timeline: {
  QuickLogNoCountEntry(date: Date())
})
