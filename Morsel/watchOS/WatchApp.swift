import SwiftData
import SwiftUI

@main
struct WatchApp: App {
  @StateObject private var sessionManager = WatchSessionManager()

  var body: some Scene {
    WindowGroup {
      WatchContentView()
        .environmentObject(AppSettings.shared)
        .modelContainer(.morsel)
        .onAppear { Analytics.setUp() }
    }
  }
}
