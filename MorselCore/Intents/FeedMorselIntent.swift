import AppIntents
import CoreMorsel
import Foundation

struct FeedMorselIntent: AppIntent {
  static let title = LocalizedStringResource("Feed Morsel")
  static let openAppWhenRun = false

  @Parameter(title: "Item", description: "The item to feed to Morsel.")
  var name: String

  @MainActor
  func perform() async throws -> some IntentResult {
    try await Adder.add(name: name, isForMorsel: true, context: .phoneIntent)

    return .result()
  }
}
