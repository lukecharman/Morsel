import SwiftUI
import WidgetKit

struct QuickLogInlineView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    Text("Morsels: \(entry.mealCount)")
      .widgetURL(URL(string: "morsel://add")!)
      .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct QuickLogNoCountInlineView: View {
  var body: some View {
    HStack(spacing: 24) {
      MonochromeMorsel(width: 30)
      Text("Add Morsel")
        .widgetURL(URL(string: "morsel://add")!)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}

