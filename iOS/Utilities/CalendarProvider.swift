import Foundation

protocol CalendarProviderInterface {
  func startOfDigestWeek(for date: Date) -> Date
}

struct CalendarProvider: CalendarProviderInterface {
  private let calendar: Calendar

  init(calendar: Calendar = .current) {
    self.calendar = calendar
  }

  func startOfDigestWeek(for date: Date) -> Date {
    var calendar = Calendar(identifier: .iso8601)
    calendar.firstWeekday = DigestConfiguration.unlockWeekday

    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return calendar.date(from: components)!
  }
}
