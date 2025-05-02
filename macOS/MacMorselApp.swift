import SwiftUI
import SwiftData

@main
struct MacMorselApp: App {
  @State private var shouldOpenMouth = false

  var body: some Scene {
    WindowGroup {
      ContentView(shouldOpenMouth: $shouldOpenMouth)
    }
    .modelContainer(.sharedContainer)
  }
}
