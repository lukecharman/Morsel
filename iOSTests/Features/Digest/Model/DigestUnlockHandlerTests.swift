import CoreMorsel
import Testing
import UserNotifications

@testable import Morsel__iOS_

@Suite("DigestUnlockHandler")
struct DigestUnlockHandlerTests {
  let provider = CalendarProvider(
    timeZone: TimeZone(secondsFromGMT: 0)!,
    locale: Locale(identifier: "en_US_POSIX"))
  var handler: DigestUnlockHandler { DigestUnlockHandler(calendarProvider: provider) }
  let cal: Calendar = {
    var c = Calendar(identifier: .iso8601)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    c.locale = Locale(identifier: "en_US_POSIX")
    return c
  }()

  @Test func availability_lockedBeforeUnlockTime() async throws {
    let weekStart = provider.startOfDigestWeek(for: Date())
    let weekEnd = provider.date(byAdding: .day, value: 7, to: weekStart)!
    let digest = DigestModel(
      weekStart: weekStart, weekEnd: weekEnd, meals: [], streakLength: 0, calendarProvider: provider
    )
    let state = handler.digestAvailabilityState(digest)
    #expect(state == .locked)
  }

  @Test func availability_unlockableAfterUnlockTime() async throws {
    let weekStart = provider.startOfDigestWeek(for: Date())
    let digest = DigestModel(
      weekStart: weekStart, weekEnd: weekStart, meals: [], streakLength: 0,
      calendarProvider: provider)
    NotificationsManager.debugUnlockTime = Date().addingTimeInterval(-60)
    defer { NotificationsManager.debugUnlockTime = nil }
    UserDefaults.standard.removeObject(forKey: handler.digestUnlockKey(for: digest))

    let state = handler.digestAvailabilityState(digest)
    #expect(state == .unlockable)
  }

  @Test func availability_unlockedAfterMarking() async throws {
    let weekStart = provider.startOfDigestWeek(for: Date())
    let digest = DigestModel(
      weekStart: weekStart, weekEnd: weekStart, meals: [], streakLength: 0,
      calendarProvider: provider)
    NotificationsManager.debugUnlockTime = Date().addingTimeInterval(-60)
    defer { NotificationsManager.debugUnlockTime = nil }
    handler.markDigestAsUnlocked(digest)
    let state = handler.digestAvailabilityState(digest)
    UserDefaults.standard.removeObject(forKey: handler.digestUnlockKey(for: digest))
    #expect(state == .unlocked)
  }

  @Test func calculateUnlockTime_handlesLeapAndWeekdays() async throws {
    guard let tuesday = makeDate(2024, 2, 27) else {
      Issue.record("date")
      return
    }
    let result = handler.calculateUnlockTime(for: tuesday, calendar: provider)
    #expect(cal.component(.weekday, from: result) == 2)
    #expect(cal.component(.hour, from: result) == MorselCalendarConfiguration.unlockHour)
    #expect(cal.component(.minute, from: result) == MorselCalendarConfiguration.unlockMinute)
    #expect(cal.component(.day, from: result) == 4)
    #expect(cal.component(.month, from: result) == 3)
  }

  @Test func calculateUnlockTime_respectsDebugOverride() async throws {
    let start = provider.startOfDigestWeek(for: Date())
    let debug = Date().addingTimeInterval(120)
    NotificationsManager.debugUnlockTime = debug
    defer { NotificationsManager.debugUnlockTime = nil }
    let result = handler.calculateUnlockTime(for: start, calendar: provider)
    #expect(result == debug)
  }

  @Test func unlockMessage_formatsExpectedString() async throws {
    let weekStart = provider.startOfDigestWeek(for: Date())
    let weekEnd = provider.date(byAdding: .day, value: 7, to: weekStart)!
    let digest = DigestModel(
      weekStart: weekStart, weekEnd: weekEnd, meals: [], streakLength: 0, calendarProvider: provider
    )
    let unlock = handler.calculateUnlockTime(for: digest.weekStart, calendar: provider)
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "EEEE"
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    let expected =
      "Check back on \(dayFormatter.string(from: unlock)) at \(timeFormatter.string(from: unlock)) to see your full digest."
    #expect(handler.unlockMessage(for: digest) == expected)
  }

  @Test func digestUnlockKeyAndMarking() async throws {
    let weekStart = provider.startOfDigestWeek(for: Date())
    let weekEnd = provider.date(byAdding: .day, value: 7, to: weekStart)!
    let digest = DigestModel(
      weekStart: weekStart, weekEnd: weekEnd, meals: [], streakLength: 0, calendarProvider: provider
    )
    let key = handler.digestUnlockKey(for: digest)
    handler.markDigestAsUnlocked(digest)
    #expect(UserDefaults.standard.bool(forKey: key))
    UserDefaults.standard.removeObject(forKey: key)
  }

  @Test func nudgeSentKeyAndMarking() async throws {
    let weekStart = provider.startOfDigestWeek(for: Date())
    let weekEnd = provider.date(byAdding: .day, value: 7, to: weekStart)!
    let digest = DigestModel(
      weekStart: weekStart, weekEnd: weekEnd, meals: [], streakLength: 0, calendarProvider: provider
    )
    let key = handler.nudgeSentKey(for: digest)
    handler.markWeeklyNudgeAsSent(for: digest)
    #expect(UserDefaults.standard.bool(forKey: key))
    UserDefaults.standard.removeObject(forKey: key)
  }

  @Test func clearDeliveredFinalDigestNotifications_removesMatching() async throws {
    let center = UNUserNotificationCenter.current()
    center.removeAllDeliveredNotifications()

    let content = UNMutableNotificationContent()
    content.title = "t"
    content.body = "b"
    content.threadIdentifier = NotificationsManager.digestThreadIdentifier
    let request = UNNotificationRequest(
      identifier: UUID().uuidString, content: content, trigger: nil)
    try await center.add(request)

    handler.clearDeliveredFinalDigestNotifications()
    try await Task.sleep(nanoseconds: 100_000_000)

    let remaining = await delivered()
    #expect(remaining.isEmpty)
  }

  func delivered() async -> [UNNotification] {
    await withCheckedContinuation { cont in
      UNUserNotificationCenter.current().getDeliveredNotifications { cont.resume(returning: $0) }
    }
  }
}

extension DigestUnlockHandlerTests {
  fileprivate func makeDate(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0
  ) -> Date? {
    var comps = DateComponents()
    comps.year = year
    comps.month = month
    comps.day = day
    comps.hour = hour
    comps.minute = minute
    comps.second = second
    return cal.date(from: comps)
  }
}
