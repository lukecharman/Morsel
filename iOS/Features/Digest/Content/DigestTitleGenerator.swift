import Foundation

enum DigestTitleGenerator {
  static let titles: [DigestMood: [DigestSeason: [String]]] = [
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
  static let moodOnly: [DigestMood: [String]] = [
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
  static let seasonOnly: [DigestSeason: [String]] = [
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
    season: DigestSeason,
    mood: DigestMood
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
