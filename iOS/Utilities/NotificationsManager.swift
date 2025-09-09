import Foundation
import NotificationCenter
import UserNotifications

struct NotificationsManager {
  /// Debug unlock time for digest testing
  static var debugUnlockTime: Date?
  static let digestThreadIdentifier = "digest_final"

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
    scheduleDigestNotifications()
    catchUpIfNeeded()
  }
  
  func requestNotificationPermissions() {
    notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
  }

  func runCatchUpCheck() {
    catchUpIfNeeded()
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
    content.userInfo = ["deepLink": "morsel://digest?offset=1"]
    content.sound = .default
    content.threadIdentifier = NotificationsManager.digestThreadIdentifier

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
    let request = UNNotificationRequest(identifier: debugDigestReminderId, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
  }

  func rescheduleDigestNotifications() {
    scheduleDigestNotifications()
  }
}

private extension NotificationsManager {

  func scheduleDigestNotifications() {
    // Kill legacy identifiers if any linger
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [digestReminderId, debugDigestReminderId])
    scheduleWeeklyDigestNotification()
  }

  func scheduleWeeklyDigestNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Morsel's got your weekly digest!"
    content.body = "Wanna see how you did this week? Morsel's been watching (politely)."
    content.userInfo = ["deepLink": "morsel://digest?offset=1"]
    content.sound = .default
    content.threadIdentifier = NotificationsManager.digestThreadIdentifier

    var dateComponents = DateComponents()
    dateComponents.weekday = DigestConfiguration.unlockWeekday
    dateComponents.hour = DigestConfiguration.unlockHour
    dateComponents.minute = DigestConfiguration.unlockMinute
    dateComponents.second = 0

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: digestReminderId, content: content, trigger: trigger)

    notificationCenter.add(request)
  }
}

// MARK: - Catch-up logic
private extension NotificationsManager {
  func catchUpIfNeeded() {
    let calendar = Calendar.current
    let now = Date()
    let weekStart = calendarProvider.startOfWeek(for: now)
    let unlockTime = calculateUnlockTime(for: weekStart, calendar: calendar)

    if now >= unlockTime && !hasSentWeeklyNudge(for: weekStart) {
      sendImmediateWeeklyNudge()
      markWeeklyNudgeSent(for: weekStart)
    }
  }

  func sendImmediateWeeklyNudge() {
    let content = UNMutableNotificationContent()
    content.title = "Morsel's got your weekly digest!"
    content.body = "Wanna see how you did this week? Morsel's been watching (politely)."
    content.userInfo = ["deepLink": "morsel://digest?offset=1"]
    content.sound = .default
    content.threadIdentifier = NotificationsManager.digestThreadIdentifier

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: "weeklyDigestCatchUp_\(weekKey(for: calendarProvider.startOfWeek(for: Date())))", content: content, trigger: trigger)
    notificationCenter.add(request)
  }

  func hasSentWeeklyNudge(for weekStart: Date) -> Bool {
    UserDefaults.standard.bool(forKey: "digest_nudge_sent_\(weekKey(for: weekStart))")
  }

  func markWeeklyNudgeSent(for weekStart: Date) {
    UserDefaults.standard.set(true, forKey: "digest_nudge_sent_\(weekKey(for: weekStart))")
  }

  func weekKey(for date: Date) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: date)
  }

  func calculateUnlockTime(for periodStart: Date, calendar: Calendar) -> Date {
    // Respect debug override only for current week
    if calendar.isDate(Date(), equalTo: periodStart, toGranularity: .weekOfYear),
       let debug = NotificationsManager.debugUnlockTime {
      return debug
    }

    let weekday = calendar.component(.weekday, from: periodStart)
    let daysToAdd = (DigestConfiguration.unlockWeekday - weekday + 7) % 7
    guard let targetDay = calendar.date(byAdding: .day, value: daysToAdd, to: periodStart) else { return periodStart }
    var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
    components.hour = DigestConfiguration.unlockHour
    components.minute = DigestConfiguration.unlockMinute
    components.second = 0
    return calendar.date(from: components) ?? targetDay
  }
}
