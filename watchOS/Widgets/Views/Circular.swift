import SwiftUI
import WidgetKit

struct QuickLogCircularView: View {
  var entry: QuickLogWithCountEntry

  var body: some View {
    ZStack {
      VStack {
        MonochromeMorsel(width: 30)
          .widgetAccentable()
        Text("\(entry.mealCount)")
          .fontDesign(.rounded)
          .widgetAccentable()
      }
    }
    .widgetURL(URL(string: "morsel://add")!)
    .containerBackground(.clear, for: .widget)
  }
}

struct QuickLogNoCountCircularView: View {
  var body: some View {
    ZStack {
      Circle().fill(.white.opacity(0.1))
      VStack {
        MonochromeMorsel(width: 30)
          .widgetAccentable()
      }
    }
    .widgetURL(URL(string: "morsel://add")!)
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

