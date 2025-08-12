import Foundation

struct DigestTimeCalculator {
  static func unlockTime(for periodStart: Date, calendar: Calendar = .current) -> Date {
    let weekday = calendar.component(.weekday, from: periodStart)
    let daysToAdd = (DigestConfiguration.unlockWeekday - weekday + 7) % 7
    guard let targetDay = calendar.date(byAdding: .day, value: daysToAdd, to: periodStart) else { return periodStart }
    var components = calendar.dateComponents([.year, .month, .day], from: targetDay)
    components.hour = DigestConfiguration.unlockHour
    components.minute = DigestConfiguration.unlockMinute
    components.second = 0
    return calendar.date(from: components) ?? targetDay
  }
}

