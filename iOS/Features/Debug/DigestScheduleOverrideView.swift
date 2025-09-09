#if DEBUG
import SwiftUI
import Foundation

struct DigestScheduleOverrideView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var weekStartDay = DigestConfiguration.weekStartWeekday
  @State private var weekStartTime = Calendar.current.date(
    from: DateComponents(
      hour: DigestConfiguration.weekStartHour,
      minute: DigestConfiguration.weekStartMinute
    )
  ) ?? Date()
  @State private var notificationDay = DigestConfiguration.unlockWeekday
  @State private var notificationTime = Calendar.current.date(
    from: DateComponents(
      hour: DigestConfiguration.unlockHour,
      minute: DigestConfiguration.unlockMinute
    )
  ) ?? Date()

  private let notificationsManager = NotificationsManager()
  private let calendar = Calendar.current

  var body: some View {
    Form {
      Section("Weekly Reset") {
        Picker("Weekday", selection: $weekStartDay) {
          ForEach(1...7, id: \.self) { idx in
            Text(calendar.weekdaySymbols[idx - 1]).tag(idx)
          }
        }
        DatePicker("Time", selection: $weekStartTime, displayedComponents: .hourAndMinute)
      }
      Section("Digest Notification") {
        Picker("Weekday", selection: $notificationDay) {
          ForEach(1...7, id: \.self) { idx in
            Text(calendar.weekdaySymbols[idx - 1]).tag(idx)
          }
        }
        DatePicker("Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
      }
      Button("Reschedule") { applyChanges() }
    }
    .navigationTitle("Digest Schedule")
  }

  private func applyChanges() {
    let weekComps = calendar.dateComponents([.hour, .minute], from: weekStartTime)
    let notifComps = calendar.dateComponents([.hour, .minute], from: notificationTime)
    DigestConfiguration.setWeekStart(weekday: weekStartDay,
                                     hour: weekComps.hour ?? 0,
                                     minute: weekComps.minute ?? 0)
    DigestConfiguration.setUnlock(weekday: notificationDay,
                                  hour: notifComps.hour ?? 0,
                                  minute: notifComps.minute ?? 0)
    notificationsManager.rescheduleDigestNotifications()
    dismiss()
  }
}
#endif
