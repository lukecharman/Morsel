import CloudKit
import CoreMorsel
import Sentry
import SwiftUI
import SwiftData
import UserNotifications

@main
struct MorselApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var sessionManager = PhoneSessionManager()
  @StateObject private var appSettings = AppSettings.shared
  @Environment(\.scenePhase) private var scenePhase

  @State private var shouldOpenMouth = false
  @State private var shouldShowDigest = false
  @State private var digestOffset: Int? = nil

  let notificationsManager = NotificationsManager()

  init() {}

  var body: some Scene {
    WindowGroup {
      ContentView(shouldOpenMouth: $shouldOpenMouth, shouldShowDigest: $shouldShowDigest, deepLinkDigestOffset: $digestOffset)
        .environmentObject(appSettings)
        .modelContainer(.morsel)
        .preferredColorScheme(appSettings.appTheme.colorScheme)
        .onOpenURL { handleDeepLink($0) }
        .onAppear { launch() }
        .onChange(of: scenePhase) { _, phase in
          if phase == .active {
            notificationsManager.runCatchUpCheck()
          }
        }
    }
  }

  func launch() {
    appDelegate.handleDeepLink = handleDeepLink(_:)
    notificationsManager.prepare()
    configureTelemetryDeck()
    configureSentry()
  }

  func handleDeepLink(_ url: URL) {
    switch url.host() {
    case "add":
      shouldOpenMouth = true
    case "digest":
      if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
         let offStr = items.first(where: { $0.name == "offset" })?.value,
         let off = Int(offStr) {
        digestOffset = off
      } else {
        digestOffset = nil
      }
      shouldShowDigest = true
    default:
      shouldOpenMouth = false
    }
  }

  func configureTelemetryDeck() {
    Analytics.setUp()
  }

  func configureSentry() {
    SentrySDK.start { options in
      options.dsn = "https://9ccb7b970531185af4de695bb82abb73@o4509382955171840.ingest.de.sentry.io/4509382973784149"
      options.tracesSampleRate = 1.0

      options.configureProfiling = {
        $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
        $0.lifecycle = .trace
      }

      options.attachScreenshot = true // This adds a screenshot to the error events
      options.attachViewHierarchy = true // This adds the view hierarchy to the error events
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  var handleDeepLink: ((URL) -> Void)?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
  }

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

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let urlString = response.notification.request.content.userInfo["deepLink"] as? String, let url = URL(string: urlString) {
      handleDeepLink?(url)
    }

    completionHandler()
  }
}
