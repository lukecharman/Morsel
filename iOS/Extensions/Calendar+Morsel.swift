import Foundation

extension Calendar {
  func startOfWeek(for date: Date) -> Date {
    // Force ISO-8601 (Monday-start) weeks but keep the current timezone
    var cal = Calendar(identifier: .iso8601)
    cal.timeZone = self.timeZone

    let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)

    return cal.date(from: comps)!
  }
}
