#if DEBUG
import SwiftUI

public struct DigestTimingSheet: View {
  @Environment(\.dismiss) private var dismiss

  // Local working copies
  @State private var weekday: Int = MorselCalendarConfiguration.unlockWeekday // 1..7 (1=Sun)
  @State private var hour: Int = MorselCalendarConfiguration.unlockHour
  @State private var minute: Int = MorselCalendarConfiguration.unlockMinute

  private let weekdays: [(label: String, value: Int)] = [
    ("Mon", 2), ("Tue", 3), ("Wed", 4), ("Thu", 5), ("Fri", 6), ("Sat", 7), ("Sun", 1)
  ]

  public init() {}

  public var body: some View {
    NavigationStack {
      Form {
        Section("Weekday") {
          Picker("Weekday", selection: $weekday) {
            ForEach(weekdays, id: \.value) { day in
              Text(day.label).tag(day.value)
            }
          }
#if os(iOS)
          .pickerStyle(.segmented)
#endif
        }

        Section("Time") {
          HStack {
            Picker("Hour", selection: $hour) {
              ForEach(0..<24, id: \.self) { h in
                Text(String(format: "%02d", h)).tag(h)
              }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("Minute", selection: $minute) {
              ForEach(0..<60, id: \.self) { m in
                Text(String(format: "%02d", m)).tag(m)
              }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
          }
          .frame(height: 140)
        }

        Section {
          Button(role: .none) {
            saveAndDismiss()
          } label: {
            Text("Confirm")
              .frame(maxWidth: .infinity)
          }

          Button(role: .destructive) {
            resetToDefaults()
          } label: {
            Text("Reset to Defaults")
              .frame(maxWidth: .infinity)
          }
        }
      }
      .navigationTitle("Digest Timing")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") { saveAndDismiss() }
        }
      }
    }
  }

  private func saveAndDismiss() {
    MorselCalendarConfiguration.unlockWeekday = weekday
    MorselCalendarConfiguration.unlockHour = hour
    MorselCalendarConfiguration.unlockMinute = minute
    dismiss()
  }

  private func resetToDefaults() {
    MorselCalendarConfiguration.reset()
    weekday = MorselCalendarConfiguration.unlockWeekday
    hour = MorselCalendarConfiguration.unlockHour
    minute = MorselCalendarConfiguration.unlockMinute
  }
}

#Preview {
  DigestTimingSheet()
}
#endif
