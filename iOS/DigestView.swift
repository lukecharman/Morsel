import SwiftUI

struct DigestView: View {
  @EnvironmentObject var appSettings: AppSettings
  @Environment(\.dismiss) private var dismiss
  let meals: [Meal]

  @State private var currentPageIndex: Int = 0
  @Namespace private var animation

  private var availableOffsets: [Int] {
    guard let earliest = meals.map(\.date).min() else { return [0] }

    let calendar = Calendar.current
    let startOfThisWeek = calendar.startOfWeek(for: Date())
    let startOfEarliestWeek = calendar.startOfWeek(for: earliest)

    let weeksBetween = calendar.dateComponents([.weekOfYear], from: startOfEarliestWeek, to: startOfThisWeek).weekOfYear ?? 0
    return Array((0...weeksBetween).reversed())
  }

  private func digest(forOffset offset: Int) -> DigestModel {
    // Offset is a positive number of weeks into the past (0 = this week, 1 = last week, etc.)
    let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: -offset, to: Date())!
    return DigestModel(forWeekContaining: targetDate, allMeals: meals)
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 16) {

        TabView(selection: $currentPageIndex) {
          ForEach(availableOffsets, id: \.self) { offset in
            let digest = digest(forOffset: offset)

            ScrollView {
              VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                  Text("Weekly Digest")
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
                  Text("You absolutely smashed it this week. Morsel is proud. You even said no to chocolate. *Chocolate!*")
                    .font(MorselFont.body)
                }

                VStack(alignment: .leading, spacing: 8) {
                  Text("Morsel’s Tip")
                    .font(MorselFont.heading)
                  Text(digest.tip.rawValue)
                    .font(MorselFont.body)
                }

                Button(action: {
                  // TODO: hook up
                }) {
                  Label("Set a goal for next week", systemImage: "target")
                    .font(MorselFont.heading)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appSettings.morselColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
              }
              .padding()
            }
            .tag(offset)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear {
          currentPageIndex = 0
        }

        HStack {
          Button(action: {
            withAnimation {
              currentPageIndex += 1
            }
          }) {
            Image(systemName: "chevron.left")
              .foregroundColor(.white)
              .padding(8)
          }
          .opacity(currentPageIndex < availableOffsets.count - 1 ? 1 : 0)
          .disabled(currentPageIndex >= availableOffsets.count - 1)
          .animation(.easeOut(duration: 0.2), value: currentPageIndex)

          Spacer()

          if currentPageIndex >= 0 && currentPageIndex < availableOffsets.count {
            let tag = availableOffsets.reversed()[currentPageIndex]
            let currentDigest = digest(forOffset: tag)
            ZStack {
              HStack {
                Text(formattedRange(for: currentDigest))
                  .font(MorselFont.body)
                  .foregroundColor(.white)
                  .lineLimit(1)
                  .minimumScaleFactor(0.7)
                  .multilineTextAlignment(.center)
                  .frame(maxWidth: .infinity)
                  .id(tag)
                  .matchedGeometryEffect(id: "weekLabel", in: animation)
              }
            }
            .animation(.easeInOut(duration: 0.3), value: tag)
          }

          Spacer()

          Button(action: {
            withAnimation {
              currentPageIndex -= 1
            }
          }) {
            Image(systemName: "chevron.right")
              .foregroundColor(.white)
              .padding(8)
          }
          .opacity(currentPageIndex > 0 ? 1 : 0)
          .disabled(currentPageIndex == 0)
          .animation(.easeOut(duration: 0.2), value: currentPageIndex)
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
      }
      .overlay(alignment: .topTrailing) {
        ToggleButton(isActive: true, systemImage: "xmark") {
          dismiss()
        }
        .padding()
      }
    }
  }
}

private struct DigestStatRow: View {
  let icon: String
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .frame(width: 24, height: 24)
        .padding(8)
        .background(.ultraThinMaterial, in: Circle())
      VStack(alignment: .leading) {
        Text(label)
          .font(MorselFont.body)
          .foregroundColor(.secondary)
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
    self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
  }
}

private extension DigestView {
  func formattedRange(for digest: DigestModel) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM"
    return "\(formatter.string(from: digest.weekStart)) – \(formatter.string(from: digest.weekEnd))"
  }
}

