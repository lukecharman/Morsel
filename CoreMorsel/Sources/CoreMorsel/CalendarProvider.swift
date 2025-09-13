import Foundation

public struct MorselCalendarConfiguration {
  public static let unlockWeekday = 2 // 2 = Monday
  public static let unlockHour = 12
  public static let unlockMinute = 15
}

public protocol CalendarProviderInterface {
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

public struct CalendarProvider: CalendarProviderInterface {
  private var calendar: Calendar

  public init(
    unlockWeekday: Int = MorselCalendarConfiguration.unlockWeekday,
    identifier: Calendar.Identifier = .iso8601,
    timeZone: TimeZone = .current,
    locale: Locale = .current
  ) {
    var cal = Calendar(identifier: identifier)
    cal.firstWeekday = unlockWeekday
    cal.timeZone = timeZone
    cal.locale = locale
    self.calendar = cal
  }

  public var timeZone: TimeZone { calendar.timeZone }
  public var locale: Locale { calendar.locale ?? .current }

  public func startOfDay(for date: Date) -> Date {
    calendar.startOfDay(for: date)
  }

  public func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
    calendar.isDate(date1, inSameDayAs: date2)
  }

  public func isDate(_ date1: Date, equalTo date2: Date, toGranularity component: Calendar.Component) -> Bool {
    calendar.isDate(date1, equalTo: date2, toGranularity: component)
  }

  public func component(_ component: Calendar.Component, from date: Date) -> Int {
    calendar.component(component, from: date)
  }

  public func date(from components: DateComponents) -> Date? {
    calendar.date(from: components)
  }

  public func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
    calendar.date(byAdding: component, value: value, to: date)
  }

  public func date(byAdding components: DateComponents, to date: Date) -> Date? {
    calendar.date(byAdding: components, to: date)
  }

  public func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
    calendar.dateComponents(components, from: date)
  }

  public func dateComponents(_ components: Set<Calendar.Component>, from start: Date, to end: Date) -> DateComponents {
    calendar.dateComponents(components, from: start, to: end)
  }

  public func startOfDigestWeek(for date: Date) -> Date {
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return calendar.date(from: components) ?? calendar.startOfDay(for: date)
  }
}
