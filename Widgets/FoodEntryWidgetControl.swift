import AppIntents
import SwiftUI
import WidgetKit

struct FoodEntryWidgetControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "FoodEntryWidgetControl") {
      ControlWidgetButton(action: AddEntryIntent()) {
        Label("Log Meal", systemImage: "plus")
      }
    }
    .displayName("Quick Log Meal")
    .description("Quickly add a meal from Control Centre or Lock Screen.")
  }
}
