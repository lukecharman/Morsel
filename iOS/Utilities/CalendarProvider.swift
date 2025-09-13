import Foundation

protocol CalendarProviderInterface {
  var timeZone: TimeZone { get }
  var locale: Locale { get }

  func startOfDigestWeek(for date: Date) -> Date
  func startOfDay(for date: Date) -> Date
  func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool
  func isDate(_ date1: Date, equalTo date2: Date, toGranularity component: Calendar.Component) -> Bool
  func component(_ component: Calendar.Component, from date: Date) -> Int
  func date(from components: DateComponents) -> Date?
  func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date?
  func date(byAdding components: DateComponents, to date: Date) -> Date?
  func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents
  func dateComponents(_ components: Set<Calendar.Component>, from start: Date, to end: Date) -> DateComponents
}

struct CalendarProvider: CalendarProviderInterface {
  private var calendar: Calendar

  init(
    identifier: Calendar.Identifier = .iso8601,
    timeZone: TimeZone = .current,
    locale: Locale = .current
  ) {
    var cal = Calendar(identifier: identifier)
    cal.firstWeekday = DigestConfiguration.unlockWeekday
    cal.timeZone = timeZone
    cal.locale = locale
    self.calendar = cal
  }

  var timeZone: TimeZone { calendar.timeZone }
  var locale: Locale { calendar.locale ?? .current }

  func startOfDay(for date: Date) -> Date {
    calendar.startOfDay(for: date)
  }

  func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
    calendar.isDate(date1, inSameDayAs: date2)
  }

  func isDate(_ date1: Date, equalTo date2: Date, toGranularity component: Calendar.Component) -> Bool {
    calendar.isDate(date1, equalTo: date2, toGranularity: component)
  }

  func component(_ component: Calendar.Component, from date: Date) -> Int {
    calendar.component(component, from: date)
  }

  func date(from components: DateComponents) -> Date? {
    calendar.date(from: components)
  }

  func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
    calendar.date(byAdding: component, value: value, to: date)
  }

  func date(byAdding components: DateComponents, to date: Date) -> Date? {
    calendar.date(byAdding: components, to: date)
  }

  func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
    calendar.dateComponents(components, from: date)
  }

  func dateComponents(_ components: Set<Calendar.Component>, from start: Date, to end: Date) -> DateComponents {
    calendar.dateComponents(components, from: start, to: end)
  }

  func startOfDigestWeek(for date: Date) -> Date {
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return calendar.date(from: components) ?? calendar.startOfDay(for: date)
  }
}
