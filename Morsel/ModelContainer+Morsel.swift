import SwiftData
import Foundation

extension ModelContainer {
  static func sharedContainer() throws -> ModelContainer {
    let schema = Schema([FoodEntry.self])

    guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.lukecharman.morsel") else {
      fatalError("💥 Failed to find App Group container.")
    }

    let databaseURL = appGroupURL.appendingPathComponent("FoodTracker.sqlite")
    let config = ModelConfiguration(
      schema: schema,
      url: databaseURL,
      allowsSave: true,
      cloudKitDatabase: .automatic
    )

    return try ModelContainer(for: schema, configurations: [config])
  }
}
