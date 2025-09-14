import CoreMorsel
import Foundation
import UserNotifications

private func digestLog(_ message: @autoclosure () -> String, function: StaticString = #function) {
  print("[DigestUnlock] \(function): \(message())")
}

final class DigestUnlockHandler {
  private let calendarProvider: CalendarProviderInterface

  init(calendarProvider: CalendarProviderInterface = CalendarProvider()) {
    self.calendarProvider = calendarProvider
  }

  // MARK: - Availability / Unlock

  func digestAvailabilityState(_ digest: DigestModel) -> DigestAvailabilityState {
    digestLog("Evaluating availability for weekStart=\(digest.weekStart) weekEnd=\(digest.weekEnd)")
    let now = Date()
    digestLog("now=\(now)")
    digestLog("Comparing week: now vs weekStart sameWeek=\(calendarProvider.isDate(now, equalTo: digest.weekStart, toGranularity: .weekOfYear))")
    guard calendarProvider.isDate(now, equalTo: digest.weekStart, toGranularity: .weekOfYear) else {
      digestLog("Different week than weekStart — auto unlocked")
      return .unlocked
    }
    let cal = calendarProvider
    let unlockTime = calculateUnlockTime(for: digest.weekEnd, calendar: cal)
    digestLog("Computed unlockTime=\(unlockTime) using period=weekEnd")
    if now < unlockTime {
      digestLog("now < unlockTime ⇒ locked")
      return .locked
    } else {
      let key = digestUnlockKey(for: digest)
      digestLog("now >= unlockTime ⇒ checking unlocked flag key=\(key)")
      let hasBeenUnlocked = UserDefaults.standard.bool(forKey: key)
      digestLog("hasBeenUnlocked=\(hasBeenUnlocked) ⇒ \(hasBeenUnlocked ? "unlocked" : "unlockable")")
      return hasBeenUnlocked ? .unlocked : .unlockable
    }
  }

  func calculateUnlockTime(for periodStart: Date, calendar: CalendarProviderInterface) -> Date {
    digestLog("calculateUnlockTime start periodStart=\(periodStart)")
    if calendar.isDate(Date(), equalTo: periodStart, toGranularity: .weekOfYear) {
      digestLog("No debug unlock time set (same week as periodStart)")
    } else {
      digestLog("Not same week as periodStart — ignoring debug unlock time if any")
    }

    let weekday = calendar.component(.weekday, from: periodStart)
    let daysToAdd = (MorselCalendarConfiguration.unlockWeekday - weekday + 7) % 7
    digestLog("weekday=\(weekday) daysToAdd=\(daysToAdd) unlockWeekday=\(MorselCalendarConfiguration.unlockWeekday)")

    guard let targetDay = calendar.date(byAdding: .day, value: daysToAdd, to: periodStart) else {
      digestLog("Failed to add days; falling back to periodStart")
      return periodStart
    }

    var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
    components.hour = MorselCalendarConfiguration.unlockHour
    components.minute = MorselCalendarConfiguration.unlockMinute
    components.second = 0

    let computed = calendar.date(from: components) ?? targetDay
    digestLog("targetDay=\(targetDay) components=(y=\(components.year ?? -1) m=\(components.month ?? -1) d=\(components.day ?? -1) h=\(components.hour ?? -1):\(components.minute ?? -1)) computed=\(computed)")
    return computed
  }

  func unlockMessage(for digest: DigestModel) -> String {
    digestLog("unlockMessage for weekStart=\(digest.weekStart)")
    let unlock = calculateUnlockTime(for: digest.weekStart, calendar: calendarProvider)
    digestLog("unlockMessage computed unlock=\(unlock) (using period=weekStart)")
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
    digestLog("unlockKey=\(key)")
    return key
  }

  func markDigestAsUnlocked(_ digest: DigestModel) {
    let digestKey = digestUnlockKey(for: digest)
    digestLog("Marking digest as unlocked key=\(digestKey)")
    UserDefaults.standard.set(true, forKey: digestKey)
  }

  func nudgeSentKey(for digest: DigestModel) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let key = "digest_nudge_sent_\(formatter.string(from: digest.weekStart))"
    digestLog("nudgeKey=\(key)")
    return key
  }

  func markWeeklyNudgeAsSent(for digest: DigestModel) {
    let key = nudgeSentKey(for: digest)
    digestLog("Marking nudge as sent key=\(key)")
    UserDefaults.standard.set(true, forKey: key)
  }

  // Convenience used by view model to clear delivered notifications
  func clearDeliveredFinalDigestNotifications() {
    digestLog("Clearing delivered notifications for thread 'digest_final'")
    let center = UNUserNotificationCenter.current()
    center.getDeliveredNotifications { notes in
      let ids = notes
        .filter { $0.request.content.threadIdentifier == "digest_final" }
        .map { $0.request.identifier }
      digestLog("Found delivered IDs count=\(ids.count)")
      if !ids.isEmpty {
        digestLog("Removing delivered notifications: \(ids)")
        center.removeDeliveredNotifications(withIdentifiers: ids)
      }
    }
  }
}
