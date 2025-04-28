import SwiftUI
import SwiftData

@main
struct MacMorselApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(.sharedContainer)
  }
}
