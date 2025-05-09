import AppIntents
import SwiftUI
import WidgetKit

struct FeedMorselWidget: ControlWidget {
  let kind: String = "FeedMorselWidget"

  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: kind) {
      ControlWidgetButton(action: LaunchAppIntent()) {
        Label("Launch Morsel", systemImage: "checkmark.circle")
      }
    }
  }
}

struct LaunchAppIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Morsel"
  static var description = IntentDescription("Opens the app.")
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    return .result()
  }
}
