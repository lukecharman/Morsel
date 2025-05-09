import CloudKit
import SwiftUI
import SwiftData

@main
struct MorselApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var sessionManager = PhoneSessionManager()
  @State private var shouldOpenMouth = false

  init() {}

  var body: some Scene {
    WindowGroup {
      ContentView(shouldOpenMouth: $shouldOpenMouth)
        .modelContainer(.sharedContainer)
        .onOpenURL { handleDeepLink($0) }
        .onAppear { Analytics.setUp() }
    }
  }

  func handleDeepLink(_ url: URL) {
    switch url.host() {
    case "add":
      shouldOpenMouth = true
    default:
      shouldOpenMouth = false
    }
  }
}

class AppState: ObservableObject {
  @Published var shouldOpenMouth: Bool = false
}

class AppDelegate: NSObject, UIApplicationDelegate {
  @preconcurrency
  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any]
  ) async -> UIBackgroundFetchResult {
    // Swift 6 Warning: Non-Sendable 'userInfo' crossing actor boundary
    // Known issue with UIKit delegate methods. Safe because I isolate handling manually.
    await MainActor.run {
      if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
         notification.notificationType == .database {
        NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
      }
    }
    return .newData
  }
}
