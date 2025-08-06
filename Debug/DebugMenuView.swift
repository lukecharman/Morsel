#if DEBUG
import SwiftUI
import UserNotifications

@MainActor
struct DebugMenuView: View {
  @State private var showStudio = false

  var body: some View {
    NavigationStack {
      List {
        Button("Schedule digest") {
          scheduleDigest()
        }
        Button("Morsel Studio") {
          showStudio = true
        }
      }
      .navigationTitle("Debug")
      .sheet(isPresented: $showStudio) {
        MorselStudio()
      }
    }
  }

  private func scheduleDigest() {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    if DigestConfiguration.isDailyDigest {
      let dayStart = calendar.startOfDay(for: Date())
      let key = "daily_digest_unlocked_\(formatter.string(from: dayStart))"
      UserDefaults.standard.removeObject(forKey: key)
    } else {
      let weekStart = calendar.startOfWeek(for: Date())
      let key = "digest_unlocked_\(formatter.string(from: weekStart))"
      UserDefaults.standard.removeObject(forKey: key)
    }

    let fireDate = Date().addingTimeInterval(30)
    NotificationsManager.debugUnlockTime = fireDate

    let content = UNMutableNotificationContent()
    if DigestConfiguration.isDailyDigest {
      content.title = "Morsel's got your daily digest!"
      content.body = "Ready to see how you did today? Morsel's been keeping track."
    } else {
      content.title = "Morsel's got your weekly digest!"
      content.body = "Wanna see how you did this week? Morsel's been watching (politely)."
    }
    content.userInfo = ["deepLink": "morsel://digest"]
    content.sound = .default
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: ["debugDigest"])
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
    let request = UNNotificationRequest(identifier: "debugDigest", content: content, trigger: trigger)
    center.add(request)
  }
}
#endif
