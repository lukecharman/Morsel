import CloudKit
import SwiftUI
import SwiftData

@main
struct MorselApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  @StateObject private var sessionManager = PhoneSessionManager()

  @State private var navigationTarget: NavigationTarget?

  init() {}

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(.sharedContainer)
        .onOpenURL { url in
          handleIncomingURL(url)
        }
        .sheet(item: $navigationTarget) { target in
          switch target {
          case .addEntry:
            NavigationStack {
              AddEntryView()
                .modelContainer(.sharedContainer)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
          }
        }
    }
  }

  private func handleIncomingURL(_ url: URL) {
    guard url.scheme == "morsel" else { return }

    switch url.host {
    case "add":
      navigationTarget = .addEntry
    default:
      break
    }
  }
}

enum NavigationTarget: Identifiable {
  case addEntry

  var id: String {
    switch self {
    case .addEntry:
      return "addEntry"
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any]
  ) async -> UIBackgroundFetchResult {
    await MainActor.run {
      if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
         notification.notificationType == .database {
        NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
      }
    }
    return .newData
  }
}
