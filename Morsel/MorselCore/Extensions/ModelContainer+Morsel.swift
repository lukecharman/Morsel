import CoreMorsel
import SwiftData
import Foundation

let appGroupIdentifier = "group.com.lukecharman.morsel"

extension ModelContainer {
  static var morsel: ModelContainer {
    do {
      let container = try ModelContainer.throwingSharedContainer()
      let context = ModelContext(container)
      _ = try? context.fetch(FetchDescriptor<FoodEntry>())
      return container
    } catch {
      Analytics.track(FailedToLoadSwiftDataContainerEvent(error: error.localizedDescription))
      fatalError("💥 Failed to load shared SwiftData container: \(error.localizedDescription)")
    }
  }
}

private extension ModelContainer {
  static var schema: Schema {
    Schema([FoodEntry.self])
  }

  static func throwingSharedContainer(fileManager: FileManager = .default) throws -> ModelContainer {
    guard let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
      Analytics.track(FailedToFindAppGroupContainerEvent())
      fatalError("💥 Failed to find App Group container.")
    }

    let databaseFilename = "Morsel.sqlite"
    let databaseURL = appGroupURL.appendingPathComponent(databaseFilename)
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
