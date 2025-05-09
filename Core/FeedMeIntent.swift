import AppIntents

struct LogMealIntent: AppIntent {
  static var title: LocalizedStringResource = "Log Meal"
  static var description = IntentDescription("Log something you actually ate.")
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Meal")
  var item: String

  func perform() async throws -> some IntentResult {
    // Your logic here to log an 'eaten' item
    print("Meal logged: \(item)")
    return .result(dialog: "Logged \(item) as a meal.")
  }
}
