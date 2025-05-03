import CoreData
import CloudKit
import SwiftUI
import SwiftData
import WatchConnectivity
import WidgetKit

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) private var colorScheme

  @State private var entries: [FoodEntry] = []
  @State private var modelContextRefreshTrigger = UUID()
  @State private var widgetReloadWorkItem: DispatchWorkItem?

  @GestureState private var addIsPressed = false

  @Binding var shouldOpenMouth: Bool

  var body: some View {
    NavigationStack {
      if entries.isEmpty {
        emptyStateView
      } else {
        filledView
      }
    }
    .overlay(alignment: .bottom) {
      MouthAddButton(shouldOpen: _shouldOpenMouth) { entry in
        add(entry)
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
          WidgetCenter.shared.reloadAllTimelines()
        }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
      modelContextRefreshTrigger = UUID()
    }
    .onReceive(NotificationCenter.default.publisher(for: .cloudKitDataChanged)) { _ in
      loadEntries()
    }
    .onChange(of: modelContextRefreshTrigger) { _, _ in
      loadEntries()
    }
    .onChange(of: entries.count) { _, new in
      updateWidget(newCount: new)
    }
  }


  private func loadEntries() {
    do {
      let descriptor = FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
      entries = try modelContext.fetch(descriptor)
      print("✅ Reloaded entries: \(entries.count)")
    } catch {
      print("💥 Failed to load entries: \(error)")
    }

    WidgetCenter.shared.reloadAllTimelines()
  }

  var emptyStateView: some View {
    VStack(spacing: 24) {
      Image(systemName: "fork.knife.circle")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
        .foregroundColor(.accentColor)
        .opacity(0.4)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

      (
        Text("Still waiting on your ")
          .font(MorselFont.title)
          .fontWeight(.medium)
      +
        Text("first bite")
          .font(MorselFont.title)
          .fontWeight(.bold)
      +
        Text("...")
          .font(MorselFont.title)
          .fontWeight(.medium)
      )
      .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
      .multilineTextAlignment(.center)

      Text("The first snack is the hardest.\nGive Morsel a tap to begin.")
        .font(MorselFont.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

      Text("↓")
        .font(MorselFont.title)
        .fontWeight(.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
    )
  }

  var filledView: some View {
    ZStack {
      LinearGradient(
        colors: gradientColors,
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      ScrollView {
        LazyVStack(alignment: .leading) {
          Section {
            MorselHeaderCard(mealCount: groupedEntries.first?.entries.count ?? 0)
          }
          ForEach(groupedEntries, id: \.date) { group in
            Text(dateString(for: group.date, entryCount: group.entries.count))
              .font(MorselFont.title)
              .padding()
            ForEach(group.entries) { entry in
              MealRow(entry: entry)
            }
          }
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
          Spacer().frame(height: 160)
        }
      }
      LinearGradient(colors: [.clear, .clear, .clear, .white], startPoint: .top, endPoint: .bottom)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
  }

  var gradientColors: [Color] {
    if colorScheme == .dark {
      return [
        Color.purple.opacity(0.2),
        Color.indigo.opacity(0.15),
        Color(.systemBackground)
      ]
    } else {
      return [
        Color.cyan.opacity(0.25),
        Color.yellow.opacity(0.1),
        Color(.systemBackground)
      ]
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

      try? modelContext.save()
      loadEntries()

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        WidgetCenter.shared.reloadAllTimelines()
        print("🗑️ Widget reload after deletion")
      }
    }
  }

  func add(_ entry: String) {
    let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    withAnimation {
      modelContext.insert(FoodEntry(name: trimmed))
      try? modelContext.save()
      loadEntries()
    }

    WidgetCenter.shared.reloadAllTimelines()
  }

  func notifyWatchOfNewMeal(entry: FoodEntry) {
    if WCSession.default.isPaired && WCSession.default.isWatchAppInstalled {
      let message = [
        "newMealName": entry.name,
        "newMealID": entry.id.uuidString,
        "origin": "phone"
      ]
      WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
        print("💥 Failed to send meal to Watch: \(error)")
      })
    }
  }
}

extension Notification.Name {
  static let cloudKitDataChanged = Notification.Name("cloudKitDataChanged")
}

#Preview {
  ContentView(shouldOpenMouth: .constant(false))
    .modelContainer(for: FoodEntry.self, inMemory: true)
}

