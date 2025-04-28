import CoreData
import CloudKit
import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var entries: [FoodEntry] = []
  @State private var showingAddEntry = false
  @State private var modelContextRefreshTrigger = UUID()
  @State private var widgetReloadWorkItem: DispatchWorkItem?

  var body: some View {
    NavigationStack {
      if entries.isEmpty {
        emptyStateView
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button(action: {
                showingAddEntry = true
              }) {
                Label("Add Entry", systemImage: "plus")
              }
            }
          }
      } else {
        filledView
          .navigationTitle("What I've Eaten")
          .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
              EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
              Button(action: {
                showingAddEntry = true
              }) {
                Label("Add Entry", systemImage: "plus")
              }
            }
          }
      }
    }
    .onAppear {
      loadEntries()
      if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.lukecharman.morsel") {
        print("📂 iPhone app is saving to: \(appGroupURL.path)")
      }

      NotificationCenter.default.addObserver(
        forName: NSPersistentCloudKitContainer.eventChangedNotification,
        object: nil,
        queue: OperationQueue.main) { _ in
          self.loadEntries()
        }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
      modelContextRefreshTrigger = UUID()
    }
    .onReceive(NotificationCenter.default.publisher(for: .cloudKitDataChanged)) { _ in
      print("🔄 CloudKit change detected — refreshing entries")
      loadEntries()
    }
    .onChange(of: modelContextRefreshTrigger) { _, _ in
      loadEntries()
    }
    .sheet(isPresented: $showingAddEntry) {
      AddEntryView()
    }
    .onChange(of: entries.count) { _, new in updateWidget(newCount: new) }
  }


  private func loadEntries() {
    do {
      let descriptor = FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
      entries = try modelContext.fetch(descriptor)
      print("✅ Reloaded entries: \(entries.count)")
    } catch {
      print("💥 Failed to load entries: \(error)")
    }
  }

  var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "fork.knife.circle")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
        .foregroundColor(.secondary)

      Text("No meals logged yet")
        .font(.title3)
        .fontWeight(.medium)

      Text("Tap the + button to add your first meal.")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  var filledView: some View {
    ScrollViewReader { proxy in
      List {
        ForEach(groupedEntries, id: \.date) { group in
          Section(header: Text(dateString(for: group.date, entryCount: group.entries.count))) {
            ForEach(group.entries) { entry in
              VStack(alignment: .leading) {
                Text(entry.name)
                  .font(.body)
                  .foregroundColor(colourForEntry(date: entry.timestamp))
                Text(entry.timestamp, format: .dateTime.hour().minute())
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              .padding(.vertical, 4)
            }
          }
          .id(group.date)
        }
        .onDelete(perform: deleteEntries)
      }
      .onAppear {
        if let todayGroup = groupedEntries.first(where: { Calendar.current.isDateInToday($0.date) }) {
          proxy.scrollTo(todayGroup.date, anchor: .top)
        }
      }
    }
  }

  private func dateString(for date: Date, entryCount: Int) -> String {
    let dayString: String
    if Calendar.current.isDateInToday(date) {
      dayString = "Today"
    } else if Calendar.current.isDateInYesterday(date) {
      dayString = "Yesterday"
    } else {
      dayString = date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    return "\(dayString) (\(entryCount))"
  }

  private func colourForEntry(date: Date) -> Color {
    if Calendar.current.isDateInToday(date) {
      return .primary
    } else if Calendar.current.isDateInYesterday(date) {
      return .secondary
    } else {
      return .gray
    }
  }

  private var groupedEntries: [(date: Date, entries: [FoodEntry])] {
    Dictionary(grouping: entries) { entry in
      Calendar.current.startOfDay(for: entry.timestamp)
    }
    .map { (key, value) in
      (date: key, entries: value)
    }
    .sorted { $0.date > $1.date }
  }

  private func addFakeEntry(daysAgo: Int, name: String) {
    let calendar = Calendar.current
    guard let fakeDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return }

    let fakeEntry = FoodEntry(name: name, timestamp: fakeDate)
    modelContext.insert(fakeEntry)
  }

  private func updateWidget(newCount: Int) {
    widgetReloadWorkItem?.cancel()

    let workItem = DispatchWorkItem {
      WidgetCenter.shared.reloadAllTimelines()
    }
    widgetReloadWorkItem = workItem

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
  }

  private func deleteEntries(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(entries[index])
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        WidgetCenter.shared.reloadAllTimelines()
        print("🗑️ Widget reload after deletion")
      }
    }
  }
}

extension Notification.Name {
  static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
}

#Preview {
  ContentView()
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
