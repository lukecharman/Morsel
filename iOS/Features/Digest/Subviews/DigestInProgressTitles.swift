import Foundation

enum DigestInProgressTitles {
  static let titles: [String] = [
    "Make This Week",
    "Shape the Week",
    "Own the Week",
    "Steer the Week",
    "Bend the Curve",
    "Claim the Days",
    "Set the Tone",
    "Nudge the Trend",
    "Write the Ending",
    "Small Wins Now",
    "Finish Strong",
    "Momentum Starts",
    "Your Move",
    "This Week, You",
    "Tilt It Better",
    "A Better Week",
    "Choose the Next",
    "Make It Count",
    "Turn It Today",
    "Guide the Week",
    "You’ve Got Time",
    "Dial It In",
    "Start Here",
    "Shift the Story",
    "Change the Vibe",
    "Set the Direction"
  ]

  static func title(for weekStart: Date) -> String {
    let secondsPerWeek: TimeInterval = 7 * 24 * 60 * 60
    let weekIndex = Int(weekStart.timeIntervalSince1970 / secondsPerWeek)
    var rng = SeededGenerator(seed: weekIndex &* 97 &+ 23)
    return titles.randomElement(using: &rng) ?? "Make This Week"
  }
}
