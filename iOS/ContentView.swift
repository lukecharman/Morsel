import CoreData
import CloudKit
import SwiftUI
import SwiftData
import WatchConnectivity
import WidgetKit

struct ContentView: View {
  let shouldGenerateFakeData = false

  @Environment(\.modelContext) private var modelContext

  @State private var entries: [FoodEntry] = []
  @State private var modelContextRefreshTrigger = UUID()
  @State private var widgetReloadWorkItem: DispatchWorkItem?
  @State private var scrollOffset: CGFloat = 0
  @State private var isDraggingHorizontally = false
  @State private var isKeyboardVisible = false
  @State private var entryText: String = ""
  @State private var isChoosingDestination = false
  @State private var showStats = false
  @State private var showExtras = false
  @State private var shouldCloseMouth: Bool = false

  @Binding var shouldOpenMouth: Bool

  var body: some View {
    ZStack {
      NavigationStack {
        if entries.isEmpty {
          emptyStateView
        } else {
          filledView
        }
      }

      if isChoosingDestination {
        DestinationPickerView(
          onPick: { isForMorsel in
            add(entryText, isForMorsel: isForMorsel)
            entryText = ""
            withAnimation {
              isChoosingDestination = false
            }
          },
          onCancel: {
            entryText = ""
            withAnimation {
              isChoosingDestination = false
            }
          }
        )
        .frame(maxHeight: .infinity)
        .ignoresSafeArea()
      }
    }
    .overlay { sidePanelView(alignment: .leading, isVisible: showStats) { StatsView(statsModel: StatsModel(modelContainer: .sharedContainer)) } }
    .overlay { sidePanelView(alignment: .trailing, isVisible: showExtras) { ExtrasView() {
      withAnimation {
        showExtras = false
        loadEntries()
      }
    } } }
    .overlay(alignment: .top) { bottomBar }
    .overlay(alignment: .bottom) { morsel }
    .onAppear { onAppear() }
    .onReceive(NotificationPublishers.keyboardWillShow) { _ in keyboardWillShow() }
    .onReceive(NotificationPublishers.keyboardWillHide) { _ in keyboardWillHide() }
    .onReceive(NotificationPublishers.cloudKitDataChanged) { _ in loadEntries() }
    .onReceive(NotificationPublishers.appDidBecomeActive) { _ in modelContextRefreshTrigger = UUID() }
    .onChange(of: modelContextRefreshTrigger) { _, _ in loadEntries() }
    .onChange(of: entries.count) { _, new in updateWidget(newCount: new) }
    .statusBarHidden(shouldBlurBackground)
  }
}

private extension ContentView {
  var morsel: some View {
    MorselView(
      shouldOpen: _shouldOpenMouth,
      shouldClose: $shouldCloseMouth,
      onTap: {
        if showStats {
          withAnimation {
            showStats = false
          }
        }
        if showExtras {
          withAnimation {
            showExtras = false
          }
        }
      }, onAdd: { text in
        entryText = text
        withAnimation {
          isChoosingDestination = true
        }
      }
    )
  }

  @ViewBuilder
  var bottomBar: some View {
    if !isKeyboardVisible {
      BottomBarView(
        showStats: $showStats,
        showExtras: $showExtras,
        isKeyboardVisible: isKeyboardVisible
      )
    }
  }

  var emptyStateView: some View {
    EmptyStateView(
      shouldBlurBackground: shouldBlurBackground) {
        if shouldBlurBackground {
          shouldOpenMouth = false
          shouldCloseMouth = true
        }
      }
  }

  var filledView: some View {
    FilledEntriesView(
      entries: entries,
      shouldBlurBackground: shouldBlurBackground,
      scrollOffset: $scrollOffset,
      isDraggingHorizontally: $isDraggingHorizontally,
      isChoosingDestination: $isChoosingDestination,
      entryText: $entryText,
      onTap: {
        if shouldBlurBackground {
          shouldOpenMouth = false
          shouldCloseMouth = true
        }
      },
      onScroll: handleScroll,
      onDelete: delete
    )
  }

  var groupedEntries: [(date: Date, entries: [FoodEntry])] {
    Dictionary(grouping: entries) { entry in
      Calendar.current.startOfDay(for: entry.timestamp)
    }
    .map { (key, value) in
      (date: key, entries: value)
    }
    .sorted { $0.date > $1.date }
  }

  var shouldBlurBackground: Bool {
    isKeyboardVisible || isChoosingDestination || showStats || showExtras
  }
}

private extension ContentView {
  func loadEntries() {
    do {
      let descriptor = FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
      entries = try modelContext.fetch(descriptor)
    } catch {
      print("Failed to load entries: \(error)")
    }

    WidgetCenter.shared.reloadAllTimelines()
  }

  func handleScroll(_ offset: CGPoint) {
    scrollOffset = offset.y
  }

  func onAppear() {
    if shouldGenerateFakeData {
      generateFakeEntries()
    }
    loadEntries()
    NotificationCenter.default.addObserver(
      forName: NSPersistentCloudKitContainer.eventChangedNotification,
      object: nil,
      queue: OperationQueue.main
    ) { _ in
      self.loadEntries()
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  func dateString(for date: Date, entryCount: Int) -> String {
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

  func colourForEntry(date: Date) -> Color {
    if Calendar.current.isDateInToday(date) {
      return .primary
    } else if Calendar.current.isDateInYesterday(date) {
      return .secondary
    } else {
      return .gray
    }
  }

  func updateWidget(newCount: Int) {
    widgetReloadWorkItem?.cancel()

    let workItem = DispatchWorkItem {
      WidgetCenter.shared.reloadAllTimelines()
    }
    widgetReloadWorkItem = workItem

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
  }

  func delete(entry: FoodEntry) {
    withAnimation {
      modelContext.delete(entry)

      try? modelContext.save()
      loadEntries()

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }

  func add(_ entry: String, isForMorsel: Bool) {
    let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    _ = withAnimation {
      Task {
        try await Adder.add(name: trimmed, isForMorsel: isForMorsel, context: .phoneApp)
        loadEntries()
      }
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
        print("Failed to send meal to Watch: \(error)")
      })
    }
  }

  func keyboardWillShow() {
    withAnimation {
      isKeyboardVisible = true
    }
  }

  func keyboardWillHide() {
    withAnimation {
      isKeyboardVisible = false
    }
  }

  @ViewBuilder
  func sidePanelView<Content: View>(
    alignment: Alignment,
    isVisible: Bool,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    ZStack {
      if isVisible {
        Color.black.opacity(0.25)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation { showStats = false; showExtras = false }
          }
        content()
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
          .transition(.move(edge: alignment == .leading ? .leading : .trailing))
          .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
      }
    }
  }
}

private extension ContentView {
  func generateFakeEntries() {
    let calendar = Calendar.current
    let mealNames = [
      "Crisps", "Banana", "Pizza", "Toast", "Yoghurt", "Protein Bar", "Chocolate",
      "Smoothie", "Biscuits", "Apple", "Ice Cream", "Salad", "Burger", "Chips", "Granola", "Cake"
    ]

    for dayOffset in 0..<30 {
      guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
      let mealsToday = Int.random(in: 3...10)

      for _ in 0..<mealsToday {
        let hour = Int.random(in: 6...22)
        let minute = Int.random(in: 0..<60)
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        guard let mealDate = calendar.date(from: components) else { continue }

        let entry = FoodEntry(
          name: mealNames.randomElement()!,
          timestamp: mealDate,
          isForMorsel: Bool.random()
        )
        modelContext.insert(entry)
      }
    }

    try? modelContext.save()
  }
}

#Preview {
  ContentView(shouldOpenMouth: .constant(false))
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
