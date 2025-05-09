import AppIntents
import Foundation

struct MorselShortcuts: AppShortcutsProvider {
  @AppShortcutsBuilder
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: FeedMorselIntent(),
      phrases: [
        "Feed \(\.$item) to ${applicationName}",
        "Give \(\.$item) to ${applicationName}",
        "Offer \(\.$item) to ${applicationName}",
        "Sacrifice \(\.$item) to ${applicationName}",
      ],
      shortTitle: "Feed Morsel",
      systemImageName: "face.smiling"
    )
  }
}

struct MorselItem: AppEntity {
  var id: String
  var name: String

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Item")

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: LocalizedStringResource(stringLiteral: name))
  }

  static var defaultQuery = FoodItemQuery()
}

struct FoodItemQuery: EntityQuery {
  var supportsFreeInput: Bool { true }

  func entities(for identifiers: [String]) async throws -> [MorselItem] {
    identifiers.map { MorselItem(id: $0, name: $0) }
  }

  func entity(for identifier: String) async throws -> MorselItem? {
    MorselItem(id: identifier, name: identifier)
  }

  func entities(matching query: String) async throws -> [MorselItem] {
    [MorselItem(id: query, name: query)]
  }
}
