import Foundation
import NotificationCenter

struct NotificationsManager {
  /// Debug unlock time for digest testing
  static var debugUnlockTime: Date?

  private let notificationCenter: UNUserNotificationCenter
  private let calendarProvider: CalendarProviderInterface
  private let digestReminderId = "weeklyDigestReminder"
  private let debugDigestReminderId = "debugDigestReminder"

  init(
    notificationCenter: UNUserNotificationCenter = .current(),
    calendarProvider: CalendarProviderInterface = CalendarProvider()
  ) {
    self.notificationCenter = notificationCenter
    self.calendarProvider = calendarProvider
  }

  func prepare() {
    requestNotificationPermissions()
    scheduleDigestNotifications()
  }

  func scheduleDebugDigest() {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [debugDigestReminderId])

    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    let weekStart = calendar.startOfWeek(for: Date())
    let key = "digest_unlocked_\(formatter.string(from: weekStart))"
    UserDefaults.standard.removeObject(forKey: key)

    let fireDate = Date().addingTimeInterval(30)
    NotificationsManager.debugUnlockTime = fireDate

    let content = UNMutableNotificationContent()
    content.title = "Morsel's got your weekly digest!"
    content.body = "Wanna see how you did this week? Morsel's been watching (politely)."
    content.userInfo = ["deepLink": "morsel://digest"]
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
    let request = UNNotificationRequest(identifier: debugDigestReminderId, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
  }
}

private extension NotificationsManager {
  func requestNotificationPermissions() {
    notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
  }

  func scheduleDigestNotifications() {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [digestReminderId])
    scheduleWeeklyDigestNotification()
  }

  func scheduleWeeklyDigestNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Morsel's got your weekly digest!"
    content.body = "Wanna see how you did this week? Morsel's been watching (politely)."
    content.userInfo = ["deepLink": "morsel://digest"]
    content.sound = .default

    var dateComponents = DateComponents()
    dateComponents.weekday = DigestConfiguration.unlockWeekday
    dateComponents.hour = DigestConfiguration.unlockHour
    dateComponents.minute = DigestConfiguration.unlockMinute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: digestReminderId, content: content, trigger: trigger)

    notificationCenter.add(request)
  }
}
