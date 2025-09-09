import Foundation

protocol CalendarProviderInterface {
  func startOfWeek(for date: Date) -> Date
}

struct CalendarProvider: CalendarProviderInterface {
  private let calendar: Calendar

  init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  func startOfWeek(for date: Date) -> Date {
    var calendar = Calendar(identifier: .iso8601)
    calendar.firstWeekday = DigestConfiguration.weekStartWeekday
    calendar.timeZone = self.calendar.timeZone

    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    guard let base = calendar.date(from: components) else { return date }

    var startComponents = calendar.dateComponents([.year, .month, .day], from: base)
    startComponents.hour = DigestConfiguration.weekStartHour
    startComponents.minute = DigestConfiguration.weekStartMinute
    startComponents.second = 0
    guard let candidate = calendar.date(from: startComponents) else { return base }

    if candidate > date {
      return calendar.date(byAdding: .weekOfYear, value: -1, to: candidate) ?? candidate
    }
    return candidate
  }
}
