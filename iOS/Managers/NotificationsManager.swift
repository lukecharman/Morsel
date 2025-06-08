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

  func prepare() {
    requestNotificationPermissions()
    scheduleTestDigestNotification()
    scheduleWeeklyDigestNotification()
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
    guard shouldScheduleDigestDeepLink else { return }

    let content = UNMutableNotificationContent()
    content.title = "Morsel’s got your weekly digest!"
    content.body = "Wanna see how you did this week? Morsel’s been watching (politely)."
    content.userInfo = ["deepLink": "morsel://digest"]
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
    let request = UNNotificationRequest(identifier: "testWeeklyDigestReminder", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request)
  }
}
