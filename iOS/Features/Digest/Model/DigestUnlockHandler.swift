import CoreMorsel
import Foundation
import UserNotifications

final class DigestUnlockHandler {
  private let calendarProvider: CalendarProviderInterface
  private let notificationCenter: UNUserNotificationCenter
  private let userDefaults: UserDefaults

  init(
    calendarProvider: CalendarProviderInterface = CalendarProvider(),
    notificationCenter: UNUserNotificationCenter = .current(),
    userDefaults: UserDefaults = .standard
  ) {
    self.calendarProvider = calendarProvider
    self.notificationCenter = notificationCenter
    self.userDefaults = userDefaults
  }

  // MARK: - Availability / Unlock

  func digestAvailabilityState(_ digest: DigestModel) -> DigestAvailabilityState {
    let now = Date()
    guard calendarProvider.isDate(now, equalTo: digest.weekStart, toGranularity: .weekOfYear) else {
      return .unlocked
    }
    let cal = calendarProvider
    let unlockTime = calculateUnlockTime(for: digest.weekEnd, calendar: cal)
    if now < unlockTime {
      return .locked
    } else {
      let key = digestUnlockKey(for: digest)
      let hasBeenUnlocked = userDefaults.bool(forKey: key)
      return hasBeenUnlocked ? .unlocked : .unlockable
    }
  }

  func calculateUnlockTime(for periodStart: Date, calendar: CalendarProviderInterface) -> Date {
    let weekday = calendar.component(.weekday, from: periodStart)
    let daysToAdd = (MorselCalendarConfiguration.unlockWeekday - weekday + 7) % 7

    guard let targetDay = calendar.date(byAdding: .day, value: daysToAdd, to: periodStart) else {
      return periodStart
    }

    var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
    components.hour = MorselCalendarConfiguration.unlockHour
    components.minute = MorselCalendarConfiguration.unlockMinute
    components.second = 0

    return calendar.date(from: components) ?? targetDay
  }

  func unlockMessage(for digest: DigestModel) -> String {
    let unlock = calculateUnlockTime(for: digest.weekStart, calendar: calendarProvider)
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "EEEE"
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    return "Check back on \(dayFormatter.string(from: unlock)) at \(timeFormatter.string(from: unlock)) to see your full digest."
  }

  func digestUnlockKey(for digest: DigestModel) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let key = "digest_unlocked_\(formatter.string(from: digest.weekStart))"
    return key
  }

  func markDigestAsUnlocked(_ digest: DigestModel) {
    let digestKey = digestUnlockKey(for: digest)
    userDefaults.set(true, forKey: digestKey)
  }

  func nudgeSentKey(for digest: DigestModel) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let key = "digest_nudge_sent_\(formatter.string(from: digest.weekStart))"
    return key
  }

  func markWeeklyNudgeAsSent(for digest: DigestModel) {
    let key = nudgeSentKey(for: digest)
    userDefaults.set(true, forKey: key)
  }

  // Convenience used by view model to clear delivered notifications
  func clearDeliveredFinalDigestNotifications() {
    let center = notificationCenter
    center.getDeliveredNotifications { notes in
      let ids = notes
        .filter { $0.request.content.threadIdentifier == "digest_final" }
        .map { $0.request.identifier }
      if !ids.isEmpty {
        center.removeDeliveredNotifications(withIdentifiers: ids)
      }
    }
  }
}
