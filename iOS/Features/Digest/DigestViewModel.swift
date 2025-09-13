import CoreMorsel
import Foundation
import SwiftUI

enum DigestSeason { case winter, spring, summer, autumn }
enum DigestMood { case noMeals, strong, tough, balanced }

final class DigestViewModel: ObservableObject {
  let meals: [FoodEntry]
  let initialOffset: Int?

  private let builder: DigestBuilderInterface
  private let lockHandler: DigestLockHandlerInterface

  @Published var currentPageIndex: Int = 0
  @Published var animatingBlurRadius: [String: Double] = [:]

  private var unblurAnimationInProgress: Set<String> = []
  private var hasTriggeredAnimation: Set<String> = []

  init(
    meals: [FoodEntry],
    initialOffset: Int? = nil,
    lockHandler: DigestLockHandlerInterface = DigestLockHandler(),
    builder: DigestBuilderInterface? = nil
  ) {
    self.meals = meals
    self.initialOffset = initialOffset
    self.builder = builder ?? DigestBuilder(meals: meals)
    self.lockHandler = lockHandler
  }

  // MARK: - Paging / Data

  var availableOffsets: [Int] {
    let calendarProvider = CalendarProvider()
    let calendar = Calendar.current

    // If no meals, preserve legacy behavior: include last week and this week.
    guard let earliestMealDate = meals.map(\.timestamp).min() else {
      return [1, 0]
    }

    let startOfCurrentWeek = calendarProvider.startOfDigestWeek(for: Date())
    let startOfEarliestMealWeek = calendarProvider.startOfDigestWeek(for: earliestMealDate)

    // Build contiguous week starts from earliest meal week to current week (inclusive)
    var weekStarts: [Date] = []
    var cursor = startOfEarliestMealWeek
    while cursor <= startOfCurrentWeek {
      weekStarts.append(cursor)
      // Safe add 1 week
      guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: cursor) else { break }
      cursor = next
    }

    // Determine which weeks are non-empty
    // For efficiency, compute each week’s inclusive end (start + 7d - 1s)
    let weekRanges: [(start: Date, endInclusive: Date)] = weekStarts.map { ws in
      let end = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: ws)!
      return (start: ws, endInclusive: end)
    }

    func hasMeals(in range: (start: Date, endInclusive: Date)) -> Bool {
      // Fast path: if no meals at all, already handled above.
      // Basic filter; meals array is expected to be modest in size for client-side filtering.
      meals.contains { $0.timestamp >= range.start && $0.timestamp <= range.endInclusive }
    }

    // Find index of first non-empty week
    let firstNonEmptyIndex = weekRanges.firstIndex(where: { hasMeals(in: $0) })

    // If somehow no non-empty weeks are found (shouldn't happen because earliest was from a meal),
    // fall back to returning just [0] (current week). But to be safe, keep legacy [1, 0].
    guard let nonEmptyIdx = firstNonEmptyIndex else {
      return [1, 0]
    }

    // Trim leading empties, but keep exactly one empty week before the first non-empty if any existed.
    let firstIndexToKeep: Int = max(0, nonEmptyIdx - 1)
    let trimmedWeekStarts = Array(weekStarts[firstIndexToKeep...])

    // Map week starts to offsets relative to current week (0 = current)
    // offset = number of weeks between weekStart and currentWeekStart
    let offsets: [Int] = trimmedWeekStarts.compactMap { ws in
      let comps = calendar.dateComponents([.weekOfYear], from: ws, to: startOfCurrentWeek)
      return comps.weekOfYear
    }

    // We built offsets oldest->newest; return in descending order (like previous code): [max ... 0]
    return offsets.sorted(by: >)
  }

  func digest(forOffset offset: Int) -> DigestModel {
    builder.digest(forOffset: offset)
  }

  // MARK: - Titles / Text

  func season(for date: Date) -> DigestSeason {
    builder.season(for: date)
  }

  func mood(for digest: DigestModel) -> DigestMood {
    builder.mood(for: digest)
  }

  func titleForDigest(_ digest: DigestModel) -> String {
    builder.titleForDigest(digest)
  }

  func encouragement(for digest: DigestModel) -> String {
    builder.encouragement(for: digest)
  }

  // MARK: - Availability / Unlock

  func digestAvailabilityState(_ digest: DigestModel) -> DigestAvailabilityState {
    lockHandler.availabilityState(for: digest, now: Date(), calendar: .current)
  }

  func calculateUnlockTime(for periodStart: Date, calendar: Calendar) -> Date {
    lockHandler.calculateUnlockTime(for: periodStart, calendar: calendar)
  }

  func unlockMessage(for digest: DigestModel) -> String {
    lockHandler.unlockMessage(for: digest, calendar: Calendar.current)
  }

  func digestUnlockKey(for digest: DigestModel) -> String {
    lockHandler.digestUnlockKey(for: digest)
  }

  private func markDigestAsUnlocked(_ digest: DigestModel) {
    lockHandler.markDigestAsUnlocked(digest)
  }

  private func nudgeSentKey(for digest: DigestModel) -> String {
    lockHandler.nudgeSentKey(for: digest)
  }

  private func markWeeklyNudgeAsSent(for digest: DigestModel) {
    lockHandler.markWeeklyNudgeAsSent(for: digest)
  }

  // MARK: - Unblur Animation

  func shouldAnimateUnblur(for digest: DigestModel, availabilityState: DigestAvailabilityState) -> Bool {
    let key = digestUnlockKey(for: digest)
    return availabilityState == .unlockable && !hasTriggeredAnimation.contains(key)
  }

  func markWillAnimate(for digest: DigestModel) {
    let key = digestUnlockKey(for: digest)
    hasTriggeredAnimation.insert(key)
  }

  func triggerUnblurAnimation(for digest: DigestModel) {
    let digestKey = digestUnlockKey(for: digest)

    animatingBlurRadius[digestKey] = 8.0
    unblurAnimationInProgress.insert(digestKey)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      withAnimation(.easeInOut(duration: 1.5)) {
        self.animatingBlurRadius[digestKey] = 0.0
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
      self.unblurAnimationInProgress.remove(digestKey)
      self.animatingBlurRadius.removeValue(forKey: digestKey)

      self.markDigestAsUnlocked(digest)
      self.markWeeklyNudgeAsSent(for: digest)

      let center = UNUserNotificationCenter.current()
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
}

