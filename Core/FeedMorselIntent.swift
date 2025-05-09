import AppIntents

struct FeedMorselIntent: AppIntent {
  static var title: LocalizedStringResource = "Feed Morsel"
  static var description = IntentDescription("Resist a craving and feed it to Morsel.")
  static var parameterSummary: some ParameterSummary {
    Summary("Feed \(\.$item) to \(.applicationName)")
  }
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Item")
  var item: String

  func perform() async throws -> some IntentResult {
    try await Adder.add(name: item, isForMorsel: true, context: .phoneIntent)
    return .result(dialog: "Fed \(item) to Morsel!")
  }
}
