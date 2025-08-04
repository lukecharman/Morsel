//
//  Notifications.swift
//  Morsel (iOS)
//
//  Created by Luke Charman on 08/06/2025.
//

import Foundation
import NotificationCenter

struct NotificationsManager {
  let shouldScheduleDigestDeepLink = false // Debug
  
  // Debug unlock time for digest testing
  static var debugUnlockTime: Date?

  func prepare() {
    requestNotificationPermissions()
    scheduleTestDigestNotification()
    scheduleDigestNotifications()
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

  func scheduleDigestNotifications() {
    // Clear any existing digest notifications first
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
      "weeklyDigestReminder",
      "dailyDigestReminder"
    ])
    
    if DigestConfiguration.isDailyDigest {
      scheduleDailyDigestNotification()
    } else {
      scheduleWeeklyDigestNotification()
    }
  }
  
  private func scheduleWeeklyDigestNotification() {
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
    let request = UNNotificationRequest(identifier: "weeklyDigestReminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
  }
  
  private func scheduleDailyDigestNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Morsel's got your daily digest!"
    content.body = "Ready to see how you did today? Morsel's been keeping track."
    content.userInfo = ["deepLink": "morsel://digest"]
    content.sound = .default

    var dateComponents = DateComponents()
    dateComponents.hour = DigestConfiguration.unlockHour
    dateComponents.minute = DigestConfiguration.unlockMinute

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: "dailyDigestReminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
  }

  func scheduleTestDigestNotification() {
    guard shouldScheduleDigestDeepLink else { return }

    // Clear any existing digest unlock keys for current period to reset animation state
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    
    // Note: This references DigestConfiguration which is private to DigestView
    // For now, clear both possible keys to be safe
    let weekStart = calendar.startOfWeek(for: Date())
    let dayStart = calendar.startOfDay(for: Date())
    let weeklyKey = "digest_unlocked_\(formatter.string(from: weekStart))"
    let dailyKey = "daily_digest_unlocked_\(formatter.string(from: dayStart))"
    
    UserDefaults.standard.removeObject(forKey: weeklyKey)
    UserDefaults.standard.removeObject(forKey: dailyKey)
    print("🐛 DEBUG: Cleared digest keys: \(weeklyKey), \(dailyKey)")

    // Set debug unlock time to 15 seconds from now
    let debugTime = Date().addingTimeInterval(15)
    NotificationsManager.debugUnlockTime = debugTime
    
    print("🐛 DEBUG: Scheduling test notification and digest unlock for \(debugTime)")

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

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
    let request = UNNotificationRequest(identifier: "testDigestReminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
  }
  
  /// Call this when switching between daily/weekly digest modes to reschedule notifications
  func rescheduleDigestNotifications() {
    scheduleDigestNotifications()
  }
}
