import CloudKit
import Sentry

import SwiftUI
import SwiftData
import UserNotifications

@main
struct MorselApp: App {
  let shouldScheduleDigestDeepLink = true

  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var sessionManager = PhoneSessionManager()

  @State private var shouldOpenMouth = false
  @State private var shouldShowDigest = false

  init() {}

  var body: some Scene {
    WindowGroup {
      ContentView(shouldOpenMouth: $shouldOpenMouth, shouldShowDigest: $shouldShowDigest)
        .environmentObject(AppSettings.shared)
        .modelContainer(.sharedContainer)
        .onOpenURL { handleDeepLink($0) }
        .onAppear { launch() }
    }
  }

  func launch() {
    appDelegate.handleDeepLink = handleDeepLink(_:)

    Analytics.setUp()

    configureSentry()

    requestNotificationPermissions()

    if shouldScheduleDigestDeepLink {
      scheduleTestDigestNotification()
    }

    scheduleWeeklyDigestNotification()
  }

  func handleDeepLink(_ url: URL) {
    switch url.host() {
    case "add":
      shouldOpenMouth = true
    case "digest":
      shouldShowDigest = true
    default:
      shouldOpenMouth = false
    }
  }


  func requestNotificationPermissions() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Notification error: \(error)")
      } else {
        print("Notifications permission granted: \(granted)")
      }
    }
  }

  func scheduleWeeklyDigestNotification() {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      let alreadyExists = requests.contains { $0.identifier == "weeklyDigestReminder" }
      if !alreadyExists {
        scheduleWeeklyDigestNotification()
      }
    }

    let content = UNMutableNotificationContent()
    content.title = "Morsel’s got your weekly digest!"
    content.body = "Wanna see how you did this week? Morsel’s been watching (politely)."
    content.userInfo = ["deepLink": "morsel://digest"]
    content.sound = .default

    var dateComponents = DateComponents()
    dateComponents.weekday = 6
    dateComponents.hour = 9

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

    let request = UNNotificationRequest(identifier: "weeklyDigestReminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
  }

  func scheduleTestDigestNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Morsel’s got your weekly digest!"
    content.body = "Wanna see how you did this week? Morsel’s been watching (politely)."
    content.userInfo = ["deepLink": "morsel://digest"]
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
    let request = UNNotificationRequest(identifier: "testWeeklyDigestReminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
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
