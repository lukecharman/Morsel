import SwiftUI
import WidgetKit

struct QuickLogCornerView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    VStack {
      Text("\(entry.mealCount)")
        .widgetCurvesContent()
        .widgetLabel("Add Morsel")
        .widgetAccentable()
        .widgetURL(URL(string: "morsel://add")!)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}

struct QuickLogNoCountCornerView: View {
  var body: some View {
    MonochromeMorsel(width: 30)
      .widgetAccentable()
      .font(.system(size: 22, weight: .bold))
      .offset(x: 4, y: 4)
      .widgetLabel("Feed")
      .widgetURL(URL(string: "morsel://add")!)
      .containerBackground(.fill.tertiary, for: .widget)
  }
}

