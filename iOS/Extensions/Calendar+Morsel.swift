import Foundation

extension Calendar {
  func startOfWeek(for date: Date) -> Date {
    var cal = Calendar(identifier: .iso8601)
    cal.firstWeekday = DigestConfiguration.weekStartWeekday
    cal.timeZone = self.timeZone

    let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    guard let base = cal.date(from: comps) else { return date }

    var startComponents = cal.dateComponents([.year, .month, .day], from: base)
    startComponents.hour = DigestConfiguration.weekStartHour
    startComponents.minute = DigestConfiguration.weekStartMinute
    startComponents.second = 0
    guard let candidate = cal.date(from: startComponents) else { return base }

    if candidate > date {
      return cal.date(byAdding: .weekOfYear, value: -1, to: candidate) ?? candidate
    }
    return candidate
  }
}
