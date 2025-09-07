import CoreMorsel
import SwiftUI
import UserNotifications

struct DigestConfiguration {
  static let unlockWeekday = 2 // 1 = Sunday
  static let unlockHour = 12
  static let unlockMinute = 15
}

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
}

private struct GlassIconButton: View {
  @EnvironmentObject var appSettings: AppSettings
  let systemName: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.title2)
        .padding(12)
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .tint(Color(appSettings.morselColor))
        .glassEffect(.regular, in: Circle())
    }
    .buttonStyle(.plain)
  }
}

private struct DigestStatRow: View {
  @EnvironmentObject var appSettings: AppSettings
  let icon: String
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .foregroundStyle(appSettings.morselColor)
        .frame(width: 24, height: 24)
        .padding(8)
        .glassEffect()
      VStack(alignment: .leading) {
        Text(label)
          .font(MorselFont.body)
          .foregroundColor(.primary.opacity(0.9))
        Text(value)
          .font(MorselFont.heading)
      }
    }
  }
}

enum MorselTip: String, CaseIterable {
  case drinkWater = "Drinking a glass of water can kill a craving before it starts."
  case brushTeeth = "Brushing your teeth can make snacking feel weird. Use it!"
  case delayCraving = "Wait 10 minutes before acting on a craving — it often fades."
  case breatheDeep = "Take three deep breaths before grabbing a snack."
  case walkItOff = "A short walk can reset your brain and kill a craving."
  case distractYourself = "Distraction works. Try a game, a book, or texting a friend."
  case hydrateFirst = "You're probably just thirsty. Have water first."
  case chewGum = "Chewing gum tricks your brain into thinking you’re already eating."
  case snackSwap = "Swap sweets for fruit. It satisfies the sweet tooth and adds fibre."
  case journal = "Write it down. Often just naming the craving gives you control."

  case protein = "Protein keeps you full longer. Make it a habit."
  case sleepMatters = "Lack of sleep spikes hunger. Get your rest."
  case mindfulBite = "Eat one bite slowly. Then stop. You’ll be amazed."
  case moveBody = "A little movement clears the mind — and resets the craving."
  case smellFood = "Smell it. You don’t always need to eat it."
  case snackOnPurpose = "If you’re gonna snack, do it mindfully and with intention."
  case planTreats = "Plan treats. Surprises = less control."
  case shopSmart = "Don’t bring it in the house. You can’t eat what’s not there."
  case nightTime = "Evening cravings hit hard. Have a strategy before 8pm."
  case stressSnack = "Notice if you’re eating from stress. Then pause."

  case identity = "Think: what would someone like me do right now?"
  case teaTrick = "Herbal tea with a strong flavour can scratch the snacking itch."
  case bananaBread = "Bake something healthier — it satisfies the ritual."
  case singleServe = "Portion out your snack instead of eating from the bag."
  case treatJar = "Have a treat jar. When it’s gone, it’s gone."
  case darkChocolate = "Dark chocolate. One square. Trust us."
  case appleCrunch = "Crunchy apples feel satisfying and take time to eat."
  case yoghurt = "Yoghurt and berries: sweet, filling, and protein-rich."
  case dontPunish = "Slipped up? Don’t punish yourself. That leads to spirals."
  case shareIt = "Want the snack? Offer to share it with someone."

  case visualise = "Picture yourself saying no — it makes it easier next time."
  case keepBusy = "Idle hands snack. Keep your hands busy."
  case putItAway = "Don’t leave it out. Out of sight, out of mouth."
  case sugarCrash = "Cravings often follow sugar crashes. Watch your meals."
  case rinse = "Rinse your mouth with mouthwash — it’s a hard reset."
  case music = "Play a song. By the end of it, your craving might be gone."
  case askWhy = "Ask yourself: why do I want this? The answer might surprise you."
  case freezeIt = "Freeze treats. You’ll think twice before defrosting."
  case logIt = "Log what you eat — accountability helps."
  case breakHabit = "Change the location. If you always snack at your desk, move."

  case snackBuddy = "Get a snack buddy. Someone to text when cravings hit."
  case smellCandle = "Scented candle trick: engage a different sense."
  case preCommit = "Tell someone your goal. It makes you stick to it."
  case visualGoal = "Stick a post-it with your goal on the fridge."
  case swapRitual = "Swap a snack-time ritual with a new one — like stretching."
  case playGame = "Open a game for 5 minutes instead of a snack drawer."
  case podcast = "Queue a podcast and go for a 10-min walk instead."
  case mirrorTalk = "Look in the mirror and say: 'Do I *really* want this?'"
  case barkMode = "Pretend you're Morsel. Would Morsel give in? Nah."
  case lightExercise = "20 jumping jacks kills a craving and gives you endorphins."

  case prepSnack = "Prep healthy snacks ahead of time — you'll thank yourself later."
  case eatEarlier = "Don’t skip meals — it backfires with late-night binges."
  case hungerScale = "Rate your hunger from 1–10 before snacking."
  case cleanUp = "Clean a small area instead — it's oddly satisfying."
  case petTime = "Pet your cat/dog/imaginary hedgehog. That works too."
  case postSnackPlan = "Have a post-snack rule: drink water + pause 10 mins."
  case gratitude = "Think of 3 things you're grateful for before opening the cupboard."
  case minty = "Minty things reduce appetite. Keep mints around."
  case fakeOrder = "Pretend you’re ordering delivery. Would you *actually* pay for this snack?"
  case standUp = "Stand up and stretch. Posture affects decisions too."

  case fiveMinuteRule = "Five-minute rule: wait, breathe, decide."
  case snackBox = "Make a snack box. One box. Once a day. That's it."
  case writeGoal = "Write your weekly goal on a sticky note and stick it somewhere visible."
  case themeWeek = "Have a theme week: fruit focus, hydration hero, etc."
  case drinkBeforeSnack = "Drink something warm before reaching for a snack."
  case eatWithHands = "Eat with your non-dominant hand to slow yourself down."
  case setTimer = "Set a timer for 10 mins. If you still want it, go ahead."
  case snackTrade = "Trade a snack for a walk or song — that counts."
  case celebrate = "Celebrate wins. Every resisted craving is a rep for your brain."
  case eveningWalk = "A 10-minute evening walk clears mind and stomach."

  case dontStockpile = "Don’t hoard snacks. You’re not a squirrel."
  case freshAir = "Go outside. Cravings hate fresh air."
  case messageAFriend = "Text a friend instead of snacking. You'll both win."
  case smellCoffee = "Smell coffee. Weirdly satisfying and 0 calories."
  case coldWater = "Cold water wakes you up *and* suppresses appetite."
  case countToTen = "Count to ten slowly before you open the snack drawer."
  case reframe = "Reframe it: 'I don’t' beats 'I can’t'."
  case tidySpace = "Tidy up your snack zone. Make it less tempting."
  case draw = "Draw something silly. You’ll forget the craving."
  case snackLess = "You don't need to snack every day. Challenge that belief."
}

struct DigestModel {
  let weekStart: Date
  let weekEnd: Date
  let mealsLogged: Int
  let cravingsResisted: Int
  let cravingsGivenIn: Int
  let mostCommonCraving: String
  let streakLength: Int
  let tip: MorselTip

  init(forWeekContaining date: Date, allMeals: [Meal]) {
    let calendar = Calendar.current
    let weekStart = calendar.startOfWeek(for: date)
    let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

    // Compute inclusiveWeekEnd after weekStart/weekEnd are set
    let inclusiveWeekEnd = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: weekStart)!
    let thisWeeksMeals = allMeals.filter { $0.date >= weekStart && $0.date <= inclusiveWeekEnd }

    self.weekStart = weekStart
    self.weekEnd = weekEnd
    self.mealsLogged = thisWeeksMeals.count
    self.cravingsResisted = thisWeeksMeals.filter { $0.type == .resisted }.count
    self.cravingsGivenIn = thisWeeksMeals.filter { $0.type == .craving }.count

    let cravings = thisWeeksMeals.filter { $0.type == .craving || $0.type == .resisted }
    let cravingNames = cravings.map { $0.name }
    let counted = Dictionary(grouping: cravingNames, by: { $0 }).mapValues { $0.count }
    self.mostCommonCraving = counted.sorted { $0.value > $1.value }.first?.key ?? "N/A"

    // Streak = consecutive non-empty weeks ending with this one
    func consecutiveNonEmptyWeeks(endingAt weekStart: Date, allMeals: [Meal], calendar: Calendar) -> Int {
      let maxWeeksBack = 52
      var streak = 0
      for i in 0..<maxWeeksBack {
        guard let checkDate = calendar.date(byAdding: .weekOfYear, value: -i, to: weekStart) else { break }
        let checkStart = calendar.startOfWeek(for: checkDate)
        let checkEnd = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: checkStart)!
        let mealsInWeek = allMeals.filter { $0.date >= checkStart && $0.date <= checkEnd }
        if mealsInWeek.isEmpty {
          break
        } else {
          streak += 1
        }
      }
      return streak
    }
    self.streakLength = consecutiveNonEmptyWeeks(endingAt: weekStart, allMeals: allMeals, calendar: calendar)

    // Deterministic tip per week
    let seed = calendar.component(.weekOfYear, from: weekStart) + calendar.component(.year, from: weekStart) * 100
    var generator = SeededGenerator(seed: seed)
    self.tip = MorselTip.allCases.randomElement(using: &generator)!
  }
  
  init(forDayContaining date: Date, allMeals: [Meal]) {
    let calendar = Calendar.current
    let dayStart = calendar.startOfDay(for: date)
    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
    
    // Compute inclusiveDayEnd after dayStart/dayEnd are set
    let inclusiveDayEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: dayStart)!
    let thisDaysMeals = allMeals.filter { $0.date >= dayStart && $0.date <= inclusiveDayEnd }
    
    self.weekStart = dayStart  // Use weekStart as the period start for consistency
    self.weekEnd = dayEnd      // Use weekEnd as the period end for consistency
    self.mealsLogged = thisDaysMeals.count
    self.cravingsResisted = thisDaysMeals.filter { $0.type == .resisted }.count
    self.cravingsGivenIn = thisDaysMeals.filter { $0.type == .craving }.count
    
    let cravings = thisDaysMeals.filter { $0.type == .craving || $0.type == .resisted }
    let cravingNames = cravings.map { $0.name }
    let counted = Dictionary(grouping: cravingNames, by: { $0 }).mapValues { $0.count }
    self.mostCommonCraving = counted.sorted { $0.value > $1.value }.first?.key ?? "N/A"
    
    // Streak = consecutive non-empty days ending with this one
    func consecutiveNonEmptyDays(endingAt dayStart: Date, allMeals: [Meal], calendar: Calendar) -> Int {
      let maxDaysBack = 365
      var streak = 0
      for i in 0..<maxDaysBack {
        guard let checkDate = calendar.date(byAdding: .day, value: -i, to: dayStart) else { break }
        let checkStart = calendar.startOfDay(for: checkDate)
        let checkEnd = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: checkStart)!
        let mealsInDay = allMeals.filter { $0.date >= checkStart && $0.date <= checkEnd }
        if mealsInDay.isEmpty {
          break
        } else {
          streak += 1
        }
      }
      return streak
    }
    self.streakLength = consecutiveNonEmptyDays(endingAt: dayStart, allMeals: allMeals, calendar: calendar)
    
    // Deterministic tip per day
    let seed = calendar.component(.day, from: dayStart) + calendar.component(.month, from: dayStart) * 100 + calendar.component(.year, from: dayStart) * 10000
    var generator = SeededGenerator(seed: seed)
    self.tip = MorselTip.allCases.randomElement(using: &generator)!
  }
}

struct Meal {
  enum MealType {
    case normal, craving, resisted
  }

  let date: Date
  let name: String
  let type: MealType
}

struct SeededGenerator: RandomNumberGenerator {
  init(seed: Int) {
    self.state = UInt64(seed)
  }

  private var state: UInt64

  mutating func next() -> UInt64 {
    state = state &* 6364136223846793005 &+ 1
    return state
  }
}

extension Calendar {
  func startOfWeek(for date: Date) -> Date {
    // Force ISO-8601 (Monday-start) weeks but keep the current timezone
    var cal = Calendar(identifier: .iso8601)
    cal.timeZone = self.timeZone
    let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return cal.date(from: comps)!
  }
}

private extension DigestView {
  // MARK: - Title generation

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

enum DigestAvailabilityState {
  case locked      // Current period, before unlock time (weekly: Friday 9 AM, daily: 9 AM each day)
  case unlockable  // Current period, after unlock time, not yet unlocked (ready to animate)
  case unlocked    // Has been unlocked (first viewed after unlock time) or past period
}

enum DigestEncouragementState {
  case noMeals
  case moreResisted
  case moreGivenIn
  case balanced

  var messages: [String] {
    switch self {
    case .noMeals:
      return [
        "Nothing logged yet – next week is a fresh start.",
        "A blank slate. Let’s fill it with good choices next time.",
        "Morsel didn’t see any meals this week. That’s okay.",
        "You’re not alone – sometimes life gets in the way.",
        "Even just one log next week is progress.",
        "Zero entries. Zero judgement.",
        "This week: rest. Next week: reflect.",
        "Morsel’s patiently waiting for your return.",
        "Start fresh on Monday – or any day.",
        "Logging takes seconds. Momentum builds from that.",
        "We’ve all had ‘off’ weeks. You’re still in the game.",
        "Dust it off. Morsel believes in you.",
        "Time to reset. You’ve got this.",
        "Step one: open the app.",
        "You’ve done hard things before. This isn’t one of them.",
        "Small steps, big change. Begin again.",
        "Zero is just the start of a climb.",
        "The best week to start logging is this one.",
        "Morsel’s memory is blank. Let’s fix that.",
        "Silence isn’t failure – it’s a pause.",
        "Missed a week? Morsel didn’t go anywhere.",
        "The graph’s empty. Let’s fill it.",
        "Blank doesn’t mean broken.",
        "One entry next week is a win.",
        "Let’s turn this around together."
      ]
    case .moreResisted:
      return [
        "You showed real control this week – Morsel’s impressed.",
        "Well done! Cravings came and you stood tall.",
        "You resisted more than you gave in – that’s big.",
        "Morsel noticed your willpower flex. Strong stuff.",
        "You’ve got bite control and brain control.",
        "This week: less munch, more mastery.",
        "You said ‘no thanks’ and meant it. Repeatedly.",
        "Nice moves. That’s how habits shift.",
        "Strong streaks come from weeks like this.",
        "Morsel’s tail is wagging. Figuratively.",
        "You made the tough choices – and logged them.",
        "Less temptation, more intention.",
        "You were on fire this week (the good kind).",
        "Solid discipline. You’re on your way.",
        "Good week for the brain–gut alliance.",
        "You didn't just react – you responded.",
        "This is what progress looks like.",
        "Those cravings didn't stand a chance.",
        "Consistency like this pays off.",
        "You earned some smug points. Spend wisely.",
        "That’s the kind of week Morsel tells friends about.",
        "Control like this isn’t easy. You made it look it.",
        "You crushed it. Quietly. Efficiently.",
        "This is how new normals get built.",
        "Morsel is lowkey proud."
      ]
    case .moreGivenIn:
      return [
        "Cravings won a bit this week, but every choice counts.",
        "No shame in a tough week. You showed up.",
        "It’s not about perfection – it’s about return.",
        "Next week is a fresh start. Morsel’s got you.",
        "Some weeks bite back. You’re still here.",
        "A few more cravings than usual? Not the end.",
        "This week wasn’t ideal. That’s okay.",
        "Slipped? It happens. Log it and move on.",
        "Awareness beats avoidance every time.",
        "One rough week won’t define the story.",
        "Compassion over criticism. Always.",
        "The fact that you’re reading this? Progress.",
        "Even logging the ‘oops’ is a win.",
        "Morsel doesn’t judge. Only encourages.",
        "Everyone falters. Not everyone comes back.",
        "Learning > perfection. Always.",
        "It’s a loop, not a ladder.",
        "Progress is still progress, even with bumps.",
        "Be gentle with yourself. Then recommit.",
        "Next week can be wildly different.",
        "The craving dragon got you this time. Rematch soon?",
        "You logged it. That’s a victory too.",
        "Call it a data point, not a defeat.",
        "This week’s a teacher, not a failure.",
        "See you in next week’s stats, champ."
      ]
    case .balanced:
      return [
        "Solid week! Keep showing up and logging those choices.",
        "Balanced effort – you're building something sustainable.",
        "Some yes, some no. That’s real life.",
        "Steady progress > dramatic swings.",
        "You logged, you navigated, you kept going.",
        "Morsel loves your consistency.",
        "Not perfect. Not chaotic. Just human.",
        "This week: a mix of wins and learnings.",
        "Balanced behaviour is better than burnout.",
        "Morsel salutes your steady hand.",
        "That’s how habits settle in – slow and real.",
        "Half resisted, half relented. Fully aware.",
        "Logging even the blurrier bits? Top tier.",
        "Some days were wins. Some were lessons.",
        "Still here. Still logging. Still progressing.",
        "That’s how a healthy baseline is built.",
        "Morsel noticed your effort. Every bit of it.",
        "One foot in front of the other."
        ,"You’re walking the middle path."
        ,"No extremes. Just engagement.",
        "A quietly excellent week.",
        "Measured choices. Measured results.",
        "A little of this, a little of that – well tracked.",
        "Keep that rhythm."
        ,"Nothing flashy. Just functional.",
        "That’s the kind of week that adds up."
      ]
    }
  }
}

// MARK: - Title generator content

private enum DigestTitleGenerator {
  // Titles grouped by mood, then by season.
  // Aim for ~200 total, mixing categories.
  static let titles: [DigestView.DigestMood: [DigestView.Season: [String]]] = [
    .noMeals: [
      .winter: [
        "Quiet Winter Week",
        "Snowed-In Summary",
        "Hibernation Mode",
        "Frosty Pause",
        "Blank Slate in Winter",
        "Winter Intermission",
        "Stillness in the Snow",
        "Cozy Reset",
        "Hibernate & Reset",
        "Winter Breather"
      ],
      .spring: [
        "Spring Reset",
        "Buds Before Blooms",
        "A Fresh Start",
        "Quiet Week, New Shoots",
        "Gentle Spring Pause",
        "Seeds Not Yet Sprouted",
        "Stillness Before Spring",
        "Springtime Blank Page",
        "Soft Start of Spring",
        "Clean Page in Spring"
      ],
      .summer: [
        "Summer Siesta",
        "Sun-Soaked Pause",
        "Lazy Days Ledger",
        "Summer Interlude",
        "Heatwave Timeout",
        "Quiet in the Sunshine",
        "Beach Day Breather",
        "Summer Blank Space",
        "Easy Breezy Break",
        "Warm-Weather Reset"
      ],
      .autumn: [
        "Autumn Intermission",
        "Leaves Falling, You Pausing",
        "Harvest a Rest",
        "Quiet in the Crisp Air",
        "Cozy Autumn Reset",
        "Pumpkin-Spice Pause",
        "Fall Reflection (Soon)",
        "Blank Page in Fall",
        "Autumn Breather",
        "Crisp Air, Clear Mind"
      ]
    ],
    .strong: [
      .winter: [
        "Winter Willpower",
        "Frost-Proof Focus",
        "Snow Day, Strong Choices",
        "Warm Core, Cold Days",
        "Crisp Discipline",
        "Hearth & Health",
        "Ice-Cold Control",
        "Winter Wins",
        "Fireside Fortitude",
        "Polar Progress"
      ],
      .spring: [
        "Spring in Your Step",
        "Blooming Discipline",
        "Fresh Starts, Strong Choices",
        "Green Shoots, Solid Habits",
        "Spring Wins",
        "Petals & Progress",
        "Bud to Bloom Bravery",
        "Spring Momentum",
        "Sunlit Self-Control",
        "Garden of Good Choices"
      ],
      .summer: [
        "Heatwave Hustle",
        "Sunshine Self-Control",
        "Summer Strength",
        "Beach-Ready Boundaries",
        "Citrus & Control",
        "Summer Wins",
        "Hot Days, Cool Choices",
        "Bright Light, Bright Choices",
        "Summer Streak",
        "Ice-Lolly Willpower"
      ],
      .autumn: [
        "Harvest of Wins",
        "Crisp Air, Clear Choices",
        "Autumn Ascend",
        "Falling Leaves, Rising Strength",
        "Golden-Hour Gains",
        "Autumn Streak",
        "Cozy Control",
        "Pumpkin-Spice Power",
        "Sweater-Weather Wins",
        "Apple-Crisp Accountability"
      ]
    ],
    .tough: [
      .winter: [
        "Winter Wobbles",
        "Thawing Out",
        "Snowdrift Detours",
        "Frost & Flex",
        "Cold Front, Keep Going",
        "Winter Lessons",
        "Hibernation Hiccups",
        "Icy Roads, Still Moving",
        "Warm Up Next Week",
        "Frostbite & Feedback"
      ],
      .spring: [
        "Spring Stumbles",
        "Puddles & Progress",
        "Mud on the Boots",
        "Rain, Reset, Repeat",
        "Gentle Spring Lessons",
        "Sprout, Don’t Sprint",
        "Blossoms After Rain",
        "Spring Tune-Up",
        "Petals & Practice",
        "Breezy, Not Easy"
      ],
      .summer: [
        "Summer Slips",
        "Heat Haze Hiccups",
        "Melting, Not Meltdown",
        "Sun, Sweat, Reset",
        "Summer Lessons",
        "Warm Days, Wiser Ways",
        "Lemonade & Learning",
        "Tide Turns Next Week",
        "Sunscreen & Self-Compassion",
        "Sand Between the Toes"
      ],
      .autumn: [
        "Autumn Aches",
        "Crisp Lessons",
        "Leaves Fall, You Rise",
        "Harvest the Learnings",
        "Foggy Starts, Clearer Finish",
        "Pumpkin-Spice Practice",
        "Cozy Course-Correct",
        "Apple-Pick Your Battles",
        "Warm Mugs, Warmer Resolve",
        "Sweater-Weather Reset"
      ]
    ],
    .balanced: [
      .winter: [
        "Steady Through the Snow",
        "Even Keel in Winter",
        "Fireside Balance",
        "Crisp & Consistent",
        "Winter Rhythm",
        "Snow-Quiet Steadiness",
        "Cozy and Consistent",
        "Winter Pace",
        "Calm in the Cold",
        "Steady Winter Steps"
      ],
      .spring: [
        "Balanced in Bloom",
        "Spring Steadiness",
        "Petals & Poise",
        "Even Spring Steps",
        "Gentle Growth",
        "Spring Rhythm",
        "Green & Grounded",
        "Breezy Balance",
        "Sprout & Steady",
        "Sunlit Steadiness"
      ],
      .summer: [
        "Summer Steady",
        "Warm-Weather Balance",
        "Even in the Heat",
        "Sun-Lit Consistency",
        "Summer Rhythm",
        "Beach-Breeze Balance",
        "Steady as the Tide",
        "Citrus & Steadiness",
        "Sunny & Centered",
        "Long-Day Levelness"
      ],
      .autumn: [
        "Autumn Equilibrium",
        "Crisp & Centered",
        "Harvest of Balance",
        "Even in the Amber Light",
        "Autumn Rhythm",
        "Steady Through Fall",
        "Sweater-Weather Steady",
        "Leaves & Levelness",
        "Cider & Consistency",
        "Cozy Balance"
      ]
    ]
  ]

  // Mood-only fallbacks
  static let moodOnly: [DigestView.DigestMood: [String]] = [
    .noMeals: [
      "Quiet Week",
      "A Pause in the Log",
      "Blank Page",
      "Reset & Return",
      "Soft Start",
      "Intermission",
      "Break in the Pattern",
      "Stillness",
      "Empty Canvas",
      "Breather"
    ],
    .strong: [
      "Wins on the Board",
      "Streak in Motion",
      "Strong Choices",
      "Control on Display",
      "Progress You Can Feel",
      "Momentum Week",
      "Power Play",
      "Solid Steps",
      "On a Roll",
      "Kept Your Cool"
    ],
    .tough: [
      "Lessons Week",
      "A Few Slips, Still Here",
      "Practice, Not Perfection",
      "Tough but True",
      "Data, Not Drama",
      "Bumps in the Road",
      "Challenging Chapter",
      "Course-Correct",
      "You Showed Up",
      "Call it a Lesson"
    ],
    .balanced: [
      "Steady Steps",
      "Balanced Effort",
      "Even Week",
      "Quietly Consistent",
      "The Middle Path",
      "Reliable Rhythm",
      "Measured Moves",
      "Smooth & Steady",
      "Consistent Cadence",
      "A Good Balance"
    ]
  ]

  // Season-only fallbacks
  static let seasonOnly: [DigestView.Season: [String]] = [
    .winter: [
      "Winter Notes",
      "Snowy Summary",
      "Fireside Reflections",
      "Crisp Air Check-In",
      "Winter Ledger",
      "Hearthside Highlights",
      "Frosty Findings",
      "Northern Notes",
      "Cozy Catch-Up",
      "Midwinter Moments"
    ],
    .spring: [
      "Spring Notes",
      "Bloom Report",
      "Fresh Growth Recap",
      "Petals & Patterns",
      "Spring Highlights",
      "Green Shoots Summary",
      "Morning Light Notes",
      "April Attitude",
      "May Momentum",
      "Springtime Snapshot"
    ],
    .summer: [
      "Summer Notes",
      "Sunshine Summary",
      "Heatwave Highlights",
      "Warm-Weather Recap",
      "Bright Days Brief",
      "Solstice Snapshot",
      "Summer Snapshot",
      "Long Days Ledger",
      "Tide & Time",
      "Citrus Notes"
    ],
    .autumn: [
      "Autumn Notes",
      "Harvest Highlights",
      "Amber Light Ledger",
      "Crisp Air Recap",
      "Falling Leaves Summary",
      "Cozy Season Check-In",
      "Autumn Snapshot",
      "Equinox Entry",
      "Cider Notes",
      "Late-Year Ledger"
    ]
  ]

  // Generic pool
  static let generic: [String] = [
    "Your Week at a Glance",
    "Choices, Logged",
    "This Week, In Bites",
    "Patterns & Progress",
    "Seven Days, One Story",
    "The Week in Review",
    "Your Eating Story",
    "A Week of Moments",
    "Small Bites, Big Picture",
    "Your Food Footprint",
    "Inputs & Insights",
    "A Week, Well Noted",
    "Notes from the Week",
    "Progress Report",
    "Reflections & Routines",
    "Signals, Not Noise",
    "A Quiet Summary",
    "Rhythms & Rations",
    "Your Appetite Atlas",
    "Mindful Moments",
    "The Gentle Ledger",
    "Week in Focus",
    "Your Choice Chronicle",
    "Tiny Wins Tally",
    "Habits in Motion",
    "Nudges & Notes",
    "The Awareness Report",
    "The Week’s Shape",
    "A Measured Week",
    "Your Consistency Card",
    "Check-In & Carry On",
    "This Week’s Signals",
    "Your Appetite Diary",
    "The Subtle Summary",
    "A Calm Recap",
    "The Week You Lived",
    "Seven-Day Signals",
    "A Week of Awareness",
    "The Honest Recap",
    "Your Gentle Audit",
    "A Little Ledger",
    "A Quiet Recap",
    "Your Habit Highlights",
    "The Weekly Snapshot",
    "Seven Simple Days",
    "The Reflection Page",
    "Your Eating Echoes",
    "A Week, Observed",
    "A Good Look Back",
    "The Rhythm Recap"
  ]

  // Dynamic title candidates that incorporate data points
  static func dynamicTitles(
    mostCommonCraving: String,
    streak: Int,
    meals: Int,
    resisted: Int,
    gaveIn: Int,
    season: DigestView.Season,
    mood: DigestView.DigestMood
  ) -> [String] {
    var list: [String] = []
    if streak >= 2 {
      list.append(contentsOf: [
        "Streak x\(streak)",
        "Keeping the Streak (\(streak))",
        "Streak Week: \(streak)",
        "Another Link in the Chain (\(streak))",
        "Chain Unbroken (\(streak))",
        "Streaks & Steps (\(streak))"
      ])
    }
    if meals > 0 {
      list.append(contentsOf: [
        "\(meals) Logs, One Week",
        "\(meals) Moments Logged",
        "A Week with \(meals) Entries",
        "\(meals) Check-Ins",
        "\(meals) Notes from You"
      ])
    }
    if resisted > 0 || gaveIn > 0 {
      list.append(contentsOf: [
        "Resisted \(resisted), Gave In \(gaveIn)",
        "Tug of War: \(resisted)–\(gaveIn)",
        "Cravings Count: \(resisted) vs \(gaveIn)"
      ])
    }
    if mostCommonCraving != "N/A" && !mostCommonCraving.trimmingCharacters(in: .whitespaces).isEmpty {
      list.append(contentsOf: [
        "The \(mostCommonCraving) Week",
        "Craving Spotlight: \(mostCommonCraving)",
        "You vs \(mostCommonCraving)",
        "\(mostCommonCraving) Came Knocking",
        "\(mostCommonCraving) on the Brain"
      ])
    }
    // Add a couple of seasonal/mood blends
    switch (season, mood) {
    case (.summer, .strong):
      list.append(contentsOf: ["Sunny Streaks", "Heat & Harmony"])
    case (.winter, .tough):
      list.append(contentsOf: ["Thaw & Try Again", "Warmth Ahead"])
    case (.spring, .balanced):
      list.append(contentsOf: ["Even in Bloom", "Fresh & Steady"])
    case (.autumn, .noMeals):
      list.append(contentsOf: ["A Quiet Fall Page", "Autumn Reset"])
    default:
      break
    }
    return list
  }
}
