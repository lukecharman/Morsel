import AppIntents
import Foundation

struct AddEntryIntent: AppIntent, OpensIntent {
  var value: Never? { nil }
  
  static var title: LocalizedStringResource = "Feed Morsel"
  static var description = IntentDescription("Opens the app and jumps to adding an entry for today.")
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult & OpensIntent {
    return .result(opensIntent: OpenURLIntent(URL(string: "morsel://add")!))
  }
}
