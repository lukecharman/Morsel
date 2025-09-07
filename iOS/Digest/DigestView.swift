import CoreMorsel
import SwiftUI
import UserNotifications

// MARK: - ViewModel

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

// MARK: - View

struct DigestView: View {
  @EnvironmentObject var appSettings: AppSettings
  @Environment(\.dismiss) private var dismiss

  let meals: [Meal]
  var initialOffset: Int? = nil
  var onClose: (() -> Void)? = nil

  @StateObject private var viewModel: DigestViewModel

  init(meals: [Meal], initialOffset: Int? = nil, onClose: (() -> Void)? = nil) {
    self.meals = meals
    self.initialOffset = initialOffset
    self.onClose = onClose
    _viewModel = StateObject(wrappedValue: DigestViewModel(meals: meals, initialOffset: initialOffset))
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        VStack(spacing: 0) {
          TabView(selection: $viewModel.currentPageIndex) {
            ForEach(viewModel.availableOffsets, id: \.self) { offset in
              let digest = viewModel.digest(forOffset: offset)
              let availabilityState = viewModel.digestAvailabilityState(digest)
              let digestKey = viewModel.digestUnlockKey(for: digest)
              let title = viewModel.titleForDigest(digest)

              ZStack {
                ScrollView {
                  VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(height: 44)

                    VStack(alignment: .leading, spacing: 8) {
                      Text(title)
                        .padding(.top, 16)
                        .font(MorselFont.title)

                      Text(viewModel.formattedRange(for: digest))
                        .font(MorselFont.body)
                        .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                      DigestStatRow(icon: "fork.knife", label: "Meals logged", value: "\(digest.mealsLogged)")
                      DigestStatRow(icon: "flame", label: "Cravings resisted", value: "\(digest.cravingsResisted)")
                      DigestStatRow(icon: "face.dashed", label: "Cravings given in to", value: "\(digest.cravingsGivenIn)")
                      DigestStatRow(icon: "flame.fill", label: "Streak", value: "\(digest.streakLength) weeks")
                      DigestStatRow(icon: "cup.and.saucer.fill", label: "Most common craving", value: digest.mostCommonCraving)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                      Text("How you did")
                        .font(MorselFont.heading)
                      Text(viewModel.encouragement(for: digest))
                        .font(MorselFont.body)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                      Text("Morsel's Tip")
                        .font(MorselFont.heading)

                      HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(digest.tip.rawValue)
                          .font(MorselFont.body)

                        Spacer(minLength: 8)

                        Button(action: {
                          Haptics.trigger(.selection)
                        }) {
                          Image(systemName: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(appSettings.morselColor)
                            .frame(width: 32, height: 32)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Share tip")
                      }
                    }
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding()
                  .blur(radius: availabilityState == .locked ? 8 : (viewModel.animatingBlurRadius[digestKey] ?? (availabilityState == .unlockable ? 8 : 0)))
                  .allowsHitTesting(availabilityState != .locked)
                  .accessibilityHidden(availabilityState == .locked)
                }
                .disabled(availabilityState == .locked)
                .ignoresSafeArea()
                .mask { mask }
                .onAppear {
                  let shouldAnimate = viewModel.shouldAnimateUnblur(for: digest, availabilityState: availabilityState)
                  if shouldAnimate {
                    viewModel.markWillAnimate(for: digest)
                    viewModel.triggerUnblurAnimation(for: digest)
                  }
                }

                if availabilityState == .locked {
                  VStack(spacing: 12) {
                    Text("This week isn't finished yet!")
                      .font(MorselFont.heading)
                    Text(viewModel.unlockMessage(for: digest))
                      .font(MorselFont.body)
                      .multilineTextAlignment(.center)
                  }
                  .padding()
                  .frame(maxWidth: .infinity)
                  .background(.ultraThinMaterial)
                  .cornerRadius(12)
                  .padding()
                }
              }
              .tag(offset)
            }
          }
          .tabViewStyle(.page(indexDisplayMode: .never))
          .onAppear {
            // Set the initial page index based on the provided initialOffset
            viewModel.currentPageIndex = viewModel.initialOffset ?? 0
          }
        }

        // Bottom controls
        VStack {
          Spacer()
          HStack(spacing: 24) {
            Button(action: {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                viewModel.currentPageIndex = min(viewModel.currentPageIndex + 1, viewModel.availableOffsets.count - 1)
              }
            }) {
              Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .opacity(viewModel.currentPageIndex < viewModel.availableOffsets.count - 1 ? 1 : 0.4)
            .disabled(viewModel.currentPageIndex >= viewModel.availableOffsets.count - 1)
            .accessibilityLabel("Previous period")

            Button(action: {
              Haptics.trigger(.selection)
              if let onClose {
                onClose()
              } else {
                dismiss()
              }
            }) {
              Image(systemName: "xmark")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close digest")

            Button(action: {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                viewModel.currentPageIndex = max(viewModel.currentPageIndex - 1, 0)
              }
            }) {
              Image(systemName: "chevron.right")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .opacity(viewModel.currentPageIndex > 0 ? 1 : 0.4)
            .disabled(viewModel.currentPageIndex == 0)
            .accessibilityLabel("Next period")
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            Capsule(style: .continuous)
              .fill(Color.clear)
              .glassEffect(.clear, in: Capsule(style: .continuous))
          )
          .padding(.bottom, geo.safeAreaInsets.bottom - 10)
        }
      }
      .ignoresSafeArea(.all)
    }
  }

  // MARK: - Mask

  private var mask: some View {
    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: .clear, location: 0.0),
        .init(color: .black, location: 0.03),
        .init(color: .black, location: 0.92),
        .init(color: .clear, location: 0.95),
        .init(color: .clear, location: 1.0)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )
    .blur(radius: 22)
  }
}
