import SwiftUI
import WidgetKit

struct QuickLogInlineView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    Text("\(entry.mealCount) Morsels Today")
      .widgetURL(URL(string: "morsel://add")!)
      .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct QuickLogNoCountInlineView: View {
  var body: some View {
    HStack(spacing: 24) {
      Text("Mmm... Morsels")
        .widgetURL(URL(string: "morsel://add")!)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}

#Preview(as: .accessoryInline, widget: {
  QuickLogWithCountWidget()
}, timeline: {
  QuickLogWithCountEntry(date: Date(), mealCount: 0)
  QuickLogWithCountEntry(date: Date().addingTimeInterval(200), mealCount: 1)
  QuickLogWithCountEntry(date: Date().addingTimeInterval(400), mealCount: 2)
})

#Preview(as: .accessoryInline, widget: {
  QuickLogNoCountWidget()
}, timeline: {
  QuickLogNoCountEntry(date: Date())
})

