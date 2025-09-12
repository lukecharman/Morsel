import Foundation

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
        "One foot in front of the other.",
        "You’re walking the middle path.",
        "No extremes. Just engagement.",
        "A quietly excellent week.",
        "Measured choices. Measured results.",
        "A little of this, a little of that – well tracked.",
        "Keep that rhythm.",
        "Nothing flashy. Just functional.",
        "That’s the kind of week that adds up."
      ]
    }
  }
}
