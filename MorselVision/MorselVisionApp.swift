import SwiftUI
import SwiftData

@main
struct MorselVisionApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(.sharedContainer)
  }
}
