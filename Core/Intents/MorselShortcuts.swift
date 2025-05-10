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
  }
  static var shortcutTileColor: ShortcutTileColor = .grayBlue
}
