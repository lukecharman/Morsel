import Foundation

// Copy shown for the current, in-progress week. Theme: "the week is what you make of it".
// We pick deterministically per-week using a seeded RNG so the message stays stable within the week.
enum DigestInProgressCopy {
  static let messages: [String] = [
    "This week is still yours to shape.",
    "The story isn’t written yet — write a good line today.",
    "Small choices today can tilt the whole week.",
    "You can still bend the curve. One log helps.",
    "Finish the week stronger than it started.",
    "There’s time left — make it count.",
    "Every entry steers the week. Steer it your way.",
    "Today’s choice changes this week’s graph.",
    "The week is what you make of it. Start now.",
    "Momentum is a decision away.",
    "A single log can reset the tone.",
    "This week responds to you — nudge it.",
    "You’re one choice from a better trend.",
    "Turn the dial today. The week will follow.",
    "Pages are blank ahead — fill them with intention.",
    "Win the next moment. The week adds up.",
    "Write the ending you want.",
    "Take the wheel — this week listens.",
    "A gentle pivot today goes a long way.",
    "It’s not over. It’s unfolding.",
    "Let today be the inflection point.",
    "Stack a small win. Then another.",
    "You can still change the vibe of this week.",
    "Make a move you’ll be proud of on Sunday.",
    "Aim for better, not perfect — starting now.",
    "Shape the week with one mindful log.",
    "This week is malleable. Press gently.",
    "Choose the next right thing.",
    "A tiny course-correct changes the destination.",
    "Close the week with intention.",
    "You’ve got influence here — use it.",
    "The next meal is the one that matters.",
    "Build momentum in minutes, not months.",
    "You’re in the driver’s seat for this week.",
    "Make the graph smile today.",
    "It’s still your week — claim it.",
    "Set the tone for the days left.",
    "Plant a seed today; harvest at week’s end.",
    "This week becomes what you practice now.",
    "Nudge the trend. Morsel’s with you."
  ]

  static func message(for weekStart: Date) -> String {
    // Derive a stable seed from the weekStart to keep message consistent within the week
    let secondsPerWeek: TimeInterval = 7 * 24 * 60 * 60
    let weekIndex = Int(weekStart.timeIntervalSince1970 / secondsPerWeek)
    var rng = SeededGenerator(seed: weekIndex &* 31_415 &+ 7)
    return messages.randomElement(using: &rng) ?? "This week is still yours to shape."
  }
}

// A simple deterministic random number generator seeded with an Int.
// Uses a basic xorshift32 algorithm for reproducible randomness.
struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt32

  init(seed: Int) {
    // Initialize state ensuring non-zero
    var seed32 = UInt32(truncatingIfNeeded: seed)
    if seed32 == 0 { seed32 = 0xdeadbeef }
    self.state = seed32
  }

  mutating func next() -> UInt64 {
    var x = state
    x ^= x << 13
    x ^= x >> 17
    x ^= x << 5
    state = x
    return UInt64(x)
  }
}
