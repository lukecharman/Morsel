import CoreData
import CloudKit
import SwiftUI
import SwiftData
import WatchConnectivity
import WidgetKit

struct ContentView: View {
  let shouldGenerateFakeData = false

  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) private var colorScheme

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

  @Binding var shouldOpenMouth: Bool

  var keyboardWillShowNotification = NotificationCenter.default.publisher(
    for: UIResponder.keyboardWillShowNotification
  )

  var keyboardWillHideNotification = NotificationCenter.default.publisher(
    for: UIResponder.keyboardWillHideNotification
  )

  var applicationDidBecomeActiveNotification = NotificationCenter.default.publisher(
    for: UIApplication.didBecomeActiveNotification
  )

  var cloudKitDataChanged = NotificationCenter.default.publisher(
    for: .cloudKitDataChanged
  )

  var body: some View {
    NavigationStack {
      if entries.isEmpty {
        EmptyStateView()
      } else {
        filledView
      }
    }
    .overlay {
      sidePanelView(alignment: .leading, isVisible: showStats) { StatsView() }
      sidePanelView(alignment: .trailing, isVisible: showExtras) { ExtrasView() }
    }
    .overlay(alignment: .top) {
      if !isKeyboardVisible {
        bottomBar
      }
    }
    .overlay(alignment: .bottom) { morsel }
    .onAppear { onAppear() }
    .onReceive(keyboardWillShowNotification) { _ in keyboardWillShow() }
    .onReceive(keyboardWillHideNotification) { _ in keyboardWillHide() }
    .onReceive(applicationDidBecomeActiveNotification) { _ in modelContextRefreshTrigger = UUID() }
    .onReceive(cloudKitDataChanged) { _ in loadEntries() }
    .onChange(of: modelContextRefreshTrigger) { _, _ in loadEntries() }
    .onChange(of: entries.count) { _, new in updateWidget(newCount: new) }
    .statusBarHidden(shouldBlurBackground)
  }

  private func loadEntries() {
    do {
      let descriptor = FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
      entries = try modelContext.fetch(descriptor)
    } catch {
      print("Failed to load entries: \(error)")
    }

    WidgetCenter.shared.reloadAllTimelines()
  }

  private func handleScroll(_ offset: CGPoint) {
    scrollOffset = offset.y
  }

  private var fadeAmount: Double {
    let offset = min(0, scrollOffset)
    let clamped = max(0, min(1, abs(offset) / 24))
    return clamped
  }

  private var filledView: some View {
    FilledEntriesView(
      entries: entries,
      shouldBlurBackground: shouldBlurBackground,
      colorScheme: colorScheme,
      scrollOffset: $scrollOffset,
      isDraggingHorizontally: $isDraggingHorizontally,
      isChoosingDestination: $isChoosingDestination,
      entryText: $entryText,
      onScroll: handleScroll,
      onAdd: add,
      onDelete: delete
    )
  }

  var morsel: some View {
    MouthAddButton(
      shouldOpen: _shouldOpenMouth,
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
      }
    ) { text in
      entryText = text
      isChoosingDestination = true
    }
  }

  var bottomBar: some View {
    GeometryReader { geo in
      VStack {
        Spacer()
        HStack(spacing: 48) {
          if !showExtras {
            Button {
              withAnimation {
                showStats.toggle()
              }
            } label: {
              Image(systemName: showStats ? "xmark" : "chart.bar")
                .font(.title2)
                .padding(12)
                .frame(width: 44, height: 44)
                .background(.thinMaterial)
                .clipShape(Circle())
            }
            .padding(.leading, 24)
            .transition(.blurReplace)
            .animation(.easeInOut(duration: 0.25), value: showStats)
          }

          Spacer()

          if !showStats {
            Button {
              withAnimation {
                showExtras.toggle()
              }
            } label: {
              Image(systemName: showExtras ? "xmark" : "ellipsis")
                .font(.title2)
                .padding(12)
                .frame(width: 44, height: 44)
                .background(.thinMaterial)
                .clipShape(Circle())
            }
            .padding(.trailing, 24)
            .transition(.blurReplace)
            .animation(.easeInOut(duration: 0.25), value: showExtras)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, geo.safeAreaInsets.bottom + 60)
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
      }
      .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
    }
    .ignoresSafeArea()
  }

  private func onAppear() {
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

  private func updateWidget(newCount: Int) {
    widgetReloadWorkItem?.cancel()

    let workItem = DispatchWorkItem {
      WidgetCenter.shared.reloadAllTimelines()
    }
    widgetReloadWorkItem = workItem

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
  }

  private func delete(entry: FoodEntry) {
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

    withAnimation {
      modelContext.insert(FoodEntry(name: trimmed, isForMorsel: isForMorsel))
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
        print("Failed to send meal to Watch: \(error)")
      })
    }
  }

  private func keyboardWillShow() {
    withAnimation {
      isKeyboardVisible = true
    }
  }

  private func keyboardWillHide() {
    withAnimation {
      isKeyboardVisible = false
    }
  }

  private var shouldBlurBackground: Bool {
    isKeyboardVisible || isChoosingDestination || showStats || showExtras
  }

  @ViewBuilder
  func sidePanelView<Content: View>(
    alignment: Alignment,
    isVisible: Bool,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    GeometryReader { geo in
      let panelWidth = geo.size.width * 0.98
      let offsetX: CGFloat = {
        switch alignment {
        case .leading: return isVisible ? -10 : -panelWidth
        case .trailing: return isVisible ? 10 : panelWidth
        default: return 0
        }
      }()

      ZStack(alignment: alignment) {
        if isVisible {
          Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
              withAnimation {
                showStats = false
                showExtras = false
              }
            }
        }

        HStack {
          if alignment == .leading {
            content()
              .frame(width: panelWidth)
              .frame(maxHeight: .infinity)
              .background(.ultraThinMaterial)
              .clipShape(
                UnevenRoundedRectangle(
                  cornerRadii: RectangleCornerRadii(
                    topLeading: alignment == .trailing ? 24 : 0,
                    bottomLeading: alignment == .trailing ? 24 : 0,
                    bottomTrailing: alignment == .trailing ? 0 : 24,
                    topTrailing: alignment == .trailing ? 0 : 24
                  )
                )
              )
              .shadow(radius: 8)
              .offset(x: offsetX)
              .animation(.spring(Spring(duration: 0.4, bounce: 0.2)), value: isVisible)
            Spacer()
          } else if alignment == .trailing {
            Spacer()
            content()
              .frame(width: panelWidth)
              .frame(maxHeight: .infinity)
              .background(.ultraThinMaterial)
              .clipShape(
                UnevenRoundedRectangle(
                  cornerRadii: RectangleCornerRadii(
                    topLeading: alignment == .trailing ? 24 : 0,
                    bottomLeading: alignment == .trailing ? 24 : 0,
                    bottomTrailing: alignment == .trailing ? 0 : 24,
                    topTrailing: alignment == .trailing ? 0 : 24
                  )
                )
              )
              .shadow(radius: 8)
              .offset(x: offsetX)
              .animation(.spring(Spring(duration: 0.4, bounce: 0.2)), value: isVisible)
          }
        }
      }
    }
  }
}

#Preview {
  ContentView(shouldOpenMouth: .constant(false))
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
