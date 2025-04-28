import SwiftUI
import SwiftData

@main
struct MorselVisionApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(sharedContainer)
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
