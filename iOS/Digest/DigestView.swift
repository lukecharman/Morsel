import CoreMorsel
import SwiftUI
import UserNotifications

struct DigestView: View {
  @EnvironmentObject var appSettings: AppSettings
  @Environment(\.dismiss) private var dismiss

  let meals: [Meal]
  var initialOffset: Int? = nil
  var onClose: (() -> Void)? = nil

  @State private var currentPageIndex: Int = 0
  @Namespace private var animation
  @State private var unblurAnimationInProgress: Set<String> = []
  @State private var animatingBlurRadius: [String: Double] = [:]
  @State private var hasTriggeredAnimation: Set<String> = []

  private var availableOffsets: [Int] {
    let calendar = Calendar.current
    // Always include last week, even if there are no meals
    guard let earliest = meals.map(\.date).min() else { return [1, 0] }

    let startOfThisWeek = calendar.startOfWeek(for: Date())
    let startOfEarliestWeek = calendar.startOfWeek(for: earliest)

    let rawWeeks = calendar.dateComponents([.weekOfYear], from: startOfEarliestWeek, to: startOfThisWeek).weekOfYear ?? 0
    let weeksBetween = max(1, rawWeeks)
    return Array((0...weeksBetween).reversed())
  }

  private func digest(forOffset offset: Int) -> DigestModel {
    // Offset is a positive number of weeks into the past (0 = this week, 1 = last week, etc.)
    let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: -offset, to: Date())!
    return DigestModel(forWeekContaining: targetDate, allMeals: meals)
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        // Main content
        VStack(spacing: 0) {
          TabView(selection: $currentPageIndex) {
            ForEach(availableOffsets, id: \.self) { offset in
              let digest = digest(forOffset: offset)
              let availabilityState = digestAvailabilityState(digest)
              let digestKey = digestUnlockKey(for: digest)
              let title = titleForDigest(digest)

              ZStack {
                ScrollView {
                  VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(height: 44)
                    VStack(alignment: .leading, spacing: 8) {
                      Text(title)
                        .padding(.top, 16)
                        .font(MorselFont.title)

                      Text(formattedRange(for: digest))
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
                      Text(encouragement(for: digest))
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
                          // Share functionality to be implemented later
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
                  .blur(radius: availabilityState == .locked ? 8 : (animatingBlurRadius[digestKey] ?? (availabilityState == .unlockable ? 8 : 0)))
                  .allowsHitTesting(availabilityState != .locked)
                  .accessibilityHidden(availabilityState == .locked)
                }
                .disabled(availabilityState == .locked)
                .ignoresSafeArea() // extend to full height
                .mask { mask }     // apply the same fade gradient blur mask as FilledEntriesView
                .onAppear {
                  // Check if this digest should animate and hasn't been animated yet
                  let digestKey = digestUnlockKey(for: digest)
                  let shouldAnimate = availabilityState == .unlockable && !hasTriggeredAnimation.contains(digestKey)
                  
                  if shouldAnimate {
                    hasTriggeredAnimation.insert(digestKey)
                    triggerUnblurAnimation(for: digest)
                  }
                }

                if availabilityState == .locked {
                  VStack(spacing: 12) {
                    Text("This week isn't finished yet!")
                      .font(MorselFont.heading)
                    Text(unlockMessage(for: digest))
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
            currentPageIndex = initialOffset ?? 0
          }
        }

        // Bottom controls — identical layout to OnboardingView, now with three buttons: < X >
        VStack {
          Spacer()
          HStack(spacing: 24) {
            // Previous (higher offset)
            Button(action: {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                currentPageIndex = min(currentPageIndex + 1, availableOffsets.count - 1)
              }
            }) {
              Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .opacity(currentPageIndex < availableOffsets.count - 1 ? 1 : 0.4)
            .disabled(currentPageIndex >= availableOffsets.count - 1)
            .accessibilityLabel("Previous period")

            // Close (center)
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

            // Next (lower offset)
            Button(action: {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                currentPageIndex = max(currentPageIndex - 1, 0)
              }
            }) {
              Image(systemName: "chevron.right")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .opacity(currentPageIndex > 0 ? 1 : 0.4)
            .disabled(currentPageIndex == 0)
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

  // Same fade gradient blur mask used in FilledEntriesView
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

  enum Season { case winter, spring, summer, autumn }
  enum DigestMood { case noMeals, strong, tough, balanced }

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
    // Matches DigestEncouragementState
  }

  func titleForDigest(_ digest: DigestModel) -> String {
    // Deterministic title per week
    let cal = Calendar.current
    let week = cal.component(.weekOfYear, from: digest.weekStart)
    let year = cal.component(.yearForWeekOfYear, from: digest.weekStart)
    let seed = week + year * 1000 + digest.streakLength * 100_000
    var rng = SeededGenerator(seed: seed)

    let s = season(for: digest.weekStart)
    let m = mood(for: digest)

    // Build a candidate pool prioritizing mood+season, then mood-only, then season-only, then generic
    var pool: [String] = []
    pool.append(contentsOf: DigestTitleGenerator.titles[m]?[s] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.moodOnly[m] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.seasonOnly[s] ?? [])
    pool.append(contentsOf: DigestTitleGenerator.generic)

    // Optionally add a few dynamic inserts using data
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

    // Fallback
    if pool.isEmpty { return "Weekly Digest" }

    // Deterministic selection
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

  private func digestAvailabilityState(_ digest: DigestModel) -> DigestAvailabilityState {
    let calendar = Calendar.current
    let now = Date()

    // If it's not the current week, it's always unlocked
    guard calendar.isDate(now, equalTo: digest.weekStart, toGranularity: .weekOfYear) else {
      return .unlocked
    }

    // Calculate the exact unlock time for this week
    let unlockTime = calculateUnlockTime(for: digest.weekStart, calendar: calendar)

    // Check if we've reached the unlock time
    if now < unlockTime {
      return .locked
    } else {
      // We're past the unlock time - check if this digest has been unlocked before
      let digestKey = digestUnlockKey(for: digest)
      let hasBeenUnlocked = UserDefaults.standard.bool(forKey: digestKey)

      if hasBeenUnlocked {
        return .unlocked
      } else {
        return .unlockable
      }
    }
  }

  private func calculateUnlockTime(for periodStart: Date, calendar: Calendar) -> Date {
    // Check for debug override (only for current week)
    if calendar.isDate(Date(), equalTo: periodStart, toGranularity: .weekOfYear),
       let debugTime = NotificationsManager.debugUnlockTime {
      return debugTime
    }

    // Find the target day in this week
    let weekday = calendar.component(.weekday, from: periodStart)
    let daysToAdd = (DigestConfiguration.unlockWeekday - weekday + 7) % 7

    guard let targetDay = calendar.date(byAdding: .day, value: daysToAdd, to: periodStart) else {
      return periodStart // Fallback to start of week
    }

    // Set the exact time
    var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
    components.hour = DigestConfiguration.unlockHour
    components.minute = DigestConfiguration.unlockMinute
    components.second = 0

    return calendar.date(from: components) ?? targetDay
  }

  private func unlockMessage(for digest: DigestModel) -> String {
    let calendar = Calendar.current
    let unlock = calculateUnlockTime(for: digest.weekStart, calendar: calendar)
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "EEEE"
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    return "Check back on \(dayFormatter.string(from: unlock)) at \(timeFormatter.string(from: unlock)) to see your full digest."
  }

  private func digestUnlockKey(for digest: DigestModel) -> String {
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

  private func triggerUnblurAnimation(for digest: DigestModel) {
    let digestKey = digestUnlockKey(for: digest)

    // Start the animation - set initial blur radius
    animatingBlurRadius[digestKey] = 8.0
    unblurAnimationInProgress.insert(digestKey)

    // Give SwiftUI a moment to render the blur, then animate
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      withAnimation(.easeInOut(duration: 1.5)) {
        self.animatingBlurRadius[digestKey] = 0.0
      }
    }

    // Clean up after animation completes (0.1s delay + 1.5s animation)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
      unblurAnimationInProgress.remove(digestKey)
      animatingBlurRadius.removeValue(forKey: digestKey)
      
      // Mark as unlocked AFTER animation completes
      self.markDigestAsUnlocked(digest)

      // Also mark the week's nudge as sent and clean up delivered notifications
      // TODO: Put htis in NotificationsManager and remove the dependency on UN here.
      self.markWeeklyNudgeAsSent(for: digest)
      let center = UNUserNotificationCenter.current()
      center.getDeliveredNotifications { notes in
        let ids = notes.filter { $0.request.content.threadIdentifier == "digest_final" }.map { $0.request.identifier }
        if !ids.isEmpty {
          center.removeDeliveredNotifications(withIdentifiers: ids)
        }
      }
    }
  }
}
