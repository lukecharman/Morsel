import AppIntents

struct AddEntryIntent: OpenIntent {
  static var title: LocalizedStringResource = "Quick Log Meal"
  static var isDiscoverable: Bool { true }

  @Parameter(title: "Target")
  var target: LaunchAppEnum

  func perform() async throws -> some IntentResult & OpensIntent  {
    let url = URL(string: "morsel://add")!
    return .result(opensIntent: OpenURLIntent(url))
  }
}

enum LaunchAppEnum: String, AppEnum {
  case addEntry

  static var typeDisplayRepresentation = TypeDisplayRepresentation("Productivity Timer's app screens")
  static var caseDisplayRepresentations = [
    LaunchAppEnum.addEntry : DisplayRepresentation("Add Entry")
  ]
}
