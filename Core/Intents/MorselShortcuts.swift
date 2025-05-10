import AppIntents
import Foundation

struct MorselShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: FeedMorselIntent(),
      phrases: [
        "Feed \(.applicationName)"
      ],
      shortTitle: "Feed Morsel",
      systemImageName: "fork.knife"
    )
    AppShortcut(
      intent: FeedMeIntent(),
      phrases: [
        "Log food in \(.applicationName)"
      ],
      shortTitle: "Feed Me",
      systemImageName: "fork.knife"
    )
  }
  static var shortcutTileColor: ShortcutTileColor = .grayBlue
}
