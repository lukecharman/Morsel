import CoreMorsel
import Foundation
import SwiftUI

enum DigestSeason { case winter, spring, summer, autumn }
enum DigestMood { case noMeals, strong, tough, balanced }

final class DigestViewModel: ObservableObject {
  // Inputs
  let meals: [FoodEntry]
  let initialOffset: Int?

  private let weekBuilder: DigestWeekBuilder
  private let modelBuilder: DigestModelBuilder
  private let unlockHandler: DigestUnlockHandler

  // UI state
  @Published var currentPageIndex: Int = 0
  @Published var animatingBlurRadius: [String: Double] = [:]

  // Animation bookkeeping
  private var unblurAnimationInProgress: Set<String> = []
  private var hasTriggeredAnimation: Set<String> = []

  init(
    meals: [FoodEntry],
    initialOffset: Int? = nil,
    weekBuilder: DigestWeekBuilder,
    modelBuilder: DigestModelBuilder,
    unlockHandler: DigestUnlockHandler
  ) {
    self.meals = meals
    self.initialOffset = initialOffset
    self.weekBuilder = weekBuilder
    self.modelBuilder = modelBuilder
    self.unlockHandler = unlockHandler
  }
  
  convenience init(
    meals: [FoodEntry],
    initialOffset: Int? = nil
  ) {
    let weekBuilder = DigestWeekBuilder()
    let modelBuilder = DigestModelBuilder(meals: meals)
    let unlockHandler = DigestUnlockHandler()

    self.init(
      meals: meals,
      initialOffset: initialOffset,
      weekBuilder: weekBuilder,
      modelBuilder: modelBuilder,
      unlockHandler: unlockHandler
    )
  }

  // MARK: - Paging / Data

  var availableOffsets: [Int] {
    weekBuilder.availableOffsets(for: meals)
  }

  func digest(forOffset offset: Int) -> DigestModel {
    modelBuilder.digest(forOffset: offset)
  }

  // MARK: - Availability / Unlock

  func digestAvailabilityState(_ digest: DigestModel) -> DigestAvailabilityState {
    unlockHandler.digestAvailabilityState(digest)
  }

  func calculateUnlockTime(for periodStart: Date, calendar: Calendar) -> Date {
    unlockHandler.calculateUnlockTime(for: periodStart, calendar: calendar)
  }

  func unlockMessage(for digest: DigestModel) -> String {
    unlockHandler.unlockMessage(for: digest)
  }

  func digestUnlockKey(for digest: DigestModel) -> String {
    unlockHandler.digestUnlockKey(for: digest)
  }

  func markDigestAsUnlocked(_ digest: DigestModel) {
    unlockHandler.markDigestAsUnlocked(digest)
  }

  func nudgeSentKey(for digest: DigestModel) -> String {
    unlockHandler.nudgeSentKey(for: digest)
  }

  func markWeeklyNudgeAsSent(for digest: DigestModel) {
    unlockHandler.markWeeklyNudgeAsSent(for: digest)
  }

  // MARK: - Titles / Text

  func season(for date: Date) -> DigestSeason {
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

      self.unlockHandler.clearDeliveredFinalDigestNotifications()
    }
  }
}

