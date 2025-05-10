import AppIntents
import Foundation
import UIKit

struct LaunchAppIntent: AppIntent {
  static let title = LocalizedStringResource("Launch Morsel")
  static let description = IntentDescription(stringLiteral: "Launch the app!")
  static let isDiscoverable = false
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult & OpensIntent {
    let url = URL(string: "morsel://add")!
    return .result(opensIntent: OpenURLIntent(url))
  }
}
