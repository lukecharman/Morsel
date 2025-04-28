import CloudKit
import SwiftUI
import SwiftData

@main
struct MorselApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  @State private var navigationTarget: NavigationTarget?
  @State private var modelContainer: ModelContainer

  init() {
    do {
      _modelContainer = try State(wrappedValue: ModelContainer.sharedContainer())
    } catch {
      fatalError("💥 Failed to load shared ModelContainer: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(modelContainer)
        .onOpenURL { url in
          handleIncomingURL(url)
        }
        .sheet(item: $navigationTarget) { target in
          switch target {
          case .addEntry:
            NavigationStack {
              AddEntryView()
                .modelContext(modelContainer.mainContext)
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
    if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
       notification.notificationType == .database {
      print("📡 CloudKit database notification received")
      NotificationCenter.default.post(name: .cloudKitDataChanged, object: nil)
    }
    return .newData
  }
}
