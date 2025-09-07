enum DigestAvailabilityState {
  case locked      // Current period, before unlock time (weekly: Friday 9 AM, daily: 9 AM each day)
  case unlockable  // Current period, after unlock time, not yet unlocked (ready to animate)
  case unlocked    // Has been unlocked (first viewed after unlock time) or past period
}
