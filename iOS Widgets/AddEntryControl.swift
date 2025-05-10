import AppIntents
import SwiftUI
import WidgetKit

struct AddEntryControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "com.lukecharman.morsel.add") {
      ControlWidgetButton(action: LaunchAppIntent()) {
        Image(systemName: "paperclip")
      }
    }
  }
}
