import AppIntents
import SwiftData

struct FeedMorselIntent: AppIntent {
  static var title: LocalizedStringResource = "Feed Morsel"
  static var description = IntentDescription("Resist a craving and feed it to Morsel.")
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Craving")
  var item: String

  func perform() async throws -> some IntentResult {
    
    print("Fed to Morsel: \(item)")
    return .result(dialog: "Fed \(item) to Morsel.")
  }
}
