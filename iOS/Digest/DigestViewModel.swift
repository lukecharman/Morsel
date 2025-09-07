import Foundation
import SwiftUI

enum Season { case winter, spring, summer, autumn }
enum DigestMood { case noMeals, strong, tough, balanced }

final class DigestViewModel: ObservableObject {
  // Inputs
  let meals: [Meal]
  let initialOffset: Int?

  // UI state
  @Published var currentPageIndex: Int = 0
  @Published var animatingBlurRadius: [String: Double] = [:]

  // Animation bookkeeping
  private var unblurAnimationInProgress: Set<String> = []
  private var hasTriggeredAnimation: Set<String> = []

  init(meals: [Meal], initialOffset: Int? = nil) {
    self.meals = meals
    self.initialOffset = initialOffset
  }

  // MARK: - Paging / Data

  var availableOffsets: [Int] {
    let calendar = Calendar.current
    guard let earliest = meals.map(\.date).min() else { return [1, 0] } // Always include last week
    let startOfThisWeek = calendar.startOfWeek(for: Date())
    let startOfEarliestWeek = calendar.startOfWeek(for: earliest)
    let rawWeeks = calendar.dateComponents([.weekOfYear], from: startOfEarliestWeek, to: startOfThisWeek).weekOfYear ?? 0
    let weeksBetween = max(1, rawWeeks)
    return Array((0...weeksBetween).reversed())
  }

  func digest(forOffset offset: Int) -> DigestModel {
    let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: -offset, to: Date())!
    return DigestModel(forWeekContaining: targetDate, allMeals: meals)
  }

  // MARK: - Availability / Unlock

  func digestAvailabilityState(_ digest: DigestModel) -> DigestAvailabilityState {
    let calendar = Calendar.current
    let now = Date()
    guard calendar.isDate(now, equalTo: digest.weekStart, toGranularity: .weekOfYear) else {
      return .unlocked
    }
    let unlockTime = calculateUnlockTime(for: digest.weekStart, calendar: calendar)
    if now < unlockTime {
      return .locked
    } else {
      let key = digestUnlockKey(for: digest)
      let hasBeenUnlocked = UserDefaults.standard.bool(forKey: key)
      return hasBeenUnlocked ? .unlocked : .unlockable
    }
  }

  func calculateUnlockTime(for periodStart: Date, calendar: Calendar) -> Date {
    if calendar.isDate(Date(), equalTo: periodStart, toGranularity: .weekOfYear),
       let debugTime = NotificationsManager.debugUnlockTime {
      return debugTime
    }

    let weekday = calendar.component(.weekday, from: periodStart)
    let daysToAdd = (DigestConfiguration.unlockWeekday - weekday + 7) % 7

    guard let targetDay = calendar.date(byAdding: .day, value: daysToAdd, to: periodStart) else {
      return periodStart
    }

    var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
    components.hour = DigestConfiguration.unlockHour
    components.minute = DigestConfiguration.unlockMinute
    components.second = 0

    return calendar.date(from: components) ?? targetDay
  }

  func unlockMessage(for digest: DigestModel) -> String {
    let calendar = Calendar.current
    let unlock = calculateUnlockTime(for: digest.weekStart, calendar: calendar)
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "EEEE"
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    return "Check back on \(dayFormatter.string(from: unlock)) at \(timeFormatter.string(from: unlock)) to see your full digest."
  }

  func digestUnlockKey(for digest: DigestModel) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return "digest_unlocked_\(formatter.string(from: digest.weekStart))"
  }

  private func markDigestAsUnlocked(_ digest: DigestModel) {
    let digestKey = digestUnlockKey(for: digest)
    UserDefaults.standard.set(true, forKey: digestKey)
  }

  private func nudgeSentKey(for digest: DigestModel) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return "digest_nudge_sent_\(formatter.string(from: digest.weekStart))"
  }

  private func markWeeklyNudgeAsSent(for digest: DigestModel) {
    let key = nudgeSentKey(for: digest)
    UserDefaults.standard.set(true, forKey: key)
  }

  // MARK: - Titles / Text

  func season(for date: Date) -> Season {
    let m = Calendar.current.component(.month, from: date)
    switch m {
    case 12, 1, 2: return .winter
    case 3, 4, 5: return .spring
    case 6, 7, 8: return .summer
    default: return .autumn
    }
  }

  func mood(for digest: DigestModel) -> DigestMood {
    if digest.mealsLogged == 0 { return .noMeals }
    if digest.cravingsResisted > digest.cravingsGivenIn { return .strong }
    if digest.cravingsGivenIn > digest.cravingsResisted { return .tough }
    return .balanced
  }

  func titleForDigest(_ digest: DigestModel) -> String {
    let cal = Calendar.current
    let week = cal.component(.weekOfYear, from: digest.weekStart)
    let year = cal.component(.yearForWeekOfYear, from: digest.weekStart)
    let seed = week + year * 1000 + digest.streakLength * 100_000
    var rng = SeededGenerator(seed: seed)

    let s = season(for: digest.weekStart)
    let m = mood(for: digest)

    var pool: [String] = []
    pool.append(contentsOf: DigestTitleGenerator.titles[m]?[s] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.moodOnly[m] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.seasonOnly[s] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.generic)

    let dynamicCandidates = DigestTitleGenerator.dynamicTitles(
      mostCommonCraving: digest.mostCommonCraving,
      streak: digest.streakLength,
      meals: digest.mealsLogged,
      resisted: digest.cravingsResisted,
      gaveIn: digest.cravingsGivenIn,
      season: s,
      mood: m
    )
    pool.append(contentsOf: dynamicCandidates)

    if pool.isEmpty { return "Weekly Digest" }
    let index = Int(rng.next() % UInt64(pool.count))
    return "“" + pool[index] + "”"
  }

  func encouragement(for digest: DigestModel) -> String {
    let state: DigestEncouragementState
    if digest.mealsLogged == 0 {
      state = .noMeals
    } else if digest.cravingsResisted > digest.cravingsGivenIn {
      state = .moreResisted
    } else if digest.cravingsGivenIn > digest.cravingsResisted {
      state = .moreGivenIn
    } else {
      state = .balanced
    }
    return state.messages.randomElement() ?? ""
  }

  func formattedRange(for digest: DigestModel) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM"
    let calendar = Calendar.current
    let displayEnd = calendar.date(byAdding: .day, value: -1, to: digest.weekEnd) ?? digest.weekEnd
    return "\(formatter.string(from: digest.weekStart)) – \(formatter.string(from: displayEnd))"
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
