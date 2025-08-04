import AppIntents
import Foundation

struct FeedMeIntent: AppIntent {
  static let title = LocalizedStringResource("Feed Me")
  static let openAppWhenRun = false

  @Parameter(title: "Item", description: "The item to feed to yourself.")
  var name: String

  @MainActor
  func perform() async throws -> some IntentResult {
    try await Adder.add(name: name, isForMorsel: false, context: .phoneIntent)

    return .result()
  }
}
