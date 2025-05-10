import SwiftData
import Foundation

extension ModelContainer {
  static var sharedContainer: ModelContainer {
    do {
      let container = try ModelContainer.throwingSharedContainer()
      let context = ModelContext(container)
      _ = try? context.fetch(FetchDescriptor<FoodEntry>())
      return container
    } catch {
      fatalError("💥 Failed to load shared SwiftData container for Watch: \(error)")
    }
  }

  static func throwingSharedContainer() throws -> ModelContainer {
    let schema = Schema([FoodEntry.self])

    guard let appGroupURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.lukecharman.morsel"
    ) else {
      fatalError("💥 Failed to find App Group container.")
    }

    let databaseURL = appGroupURL.appendingPathComponent("Morsel.sqlite")
    let config = ModelConfiguration(
      schema: schema,
      url: databaseURL,
      allowsSave: true,
      cloudKitDatabase: .automatic
    )

    return try ModelContainer(for: schema, configurations: [config])
  }
}

extension ModelContext {
  @MainActor
  func deleteAll<T: PersistentModel>(_ type: T.Type) -> Bool {
    let descriptor = FetchDescriptor<T>()
    do {
      for item in try self.fetch(descriptor) {
        self.delete(item)
      }
      try self.save()
      return true
    } catch {
      return false
    }
  }
}
