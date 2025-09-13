import CoreMorsel
import Foundation
import SwiftUI

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

  func digest(at offset: Int) -> DigestModel {
    modelBuilder.digest(at: offset)
  }

  // MARK: - Availability / Unlock

  func digestAvailabilityState(_ digest: DigestModel) -> DigestAvailabilityState {
    unlockHandler.digestAvailabilityState(digest)
  }

  func calculateUnlockTime(for periodStart: Date, calendar: CalendarProviderInterface) -> Date {
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
