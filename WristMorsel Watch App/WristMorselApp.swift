import SwiftData
import SwiftUI

@main
struct WristMorsel_Watch_AppApp: App {
  var body: some Scene {
    WindowGroup {
      WatchContentView().modelContainer(sharedContainer)
    }
  }

  var sharedContainer: ModelContainer {
    do {
      return try ModelContainer.sharedContainer()
    } catch {
      fatalError("💥 Failed to load shared SwiftData container for Watch: \(error)")
    }
  }
}
