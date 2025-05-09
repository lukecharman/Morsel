import SwiftData
import SwiftUI

@main
struct WristMorsel_Watch_AppApp: App {
  @StateObject private var sessionManager = WatchSessionManager()

  var body: some Scene {
    WindowGroup {
      WatchContentView()
        .modelContainer(.sharedContainer)
        .onAppear { Analytics.setUp() }
    }
  }
}
