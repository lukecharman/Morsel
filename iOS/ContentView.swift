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

  @StateObject private var keyboard = KeyboardObserver()

  @GestureState private var addIsPressed = false

  @Binding var shouldOpenMouth: Bool

  var body: some View {
    NavigationStack {
      if entries.isEmpty {
        EmptyStateView()
      } else {
        filledView
      }
    }
    .overlay(alignment: .top) {
      if !isKeyboardVisible {
        GeometryReader { geo in
          VStack {
            Spacer()
            HStack(spacing: 48) {
              Button {
                showStats = true
              } label: {
                Image(systemName: "chart.bar")
                  .font(.title2)
                  .padding(12)
                  .frame(width: 44, height: 44)
                  .background(.thinMaterial)
                  .clipShape(Circle())
              }
              .padding(.leading, 24)

              Spacer()

              Button {
                showExtras = true
              } label: {
                Image(systemName: "ellipsis")
                  .font(.title2)
                  .padding(12)
                  .frame(width: 44, height: 44)
                  .background(.thinMaterial)
                  .clipShape(Circle())
              }
              .padding(.trailing, 24)
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
    }
    .overlay(alignment: .bottom) {
      MouthAddButton(shouldOpen: _shouldOpenMouth) { text in
        entryText = text
        isChoosingDestination = true
      }
    }
    .onAppear {
      if shouldGenerateFakeData {
        generateFakeEntries()
      }
      loadEntries()
      NotificationCenter.default.addObserver(
        forName: NSPersistentCloudKitContainer.eventChangedNotification,
        object: nil,
        queue: OperationQueue.main) { _ in
          self.loadEntries()
          WidgetCenter.shared.reloadAllTimelines()
        }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
      withAnimation {
        isKeyboardVisible = true
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
      withAnimation {
        isKeyboardVisible = false
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
    .statusBarHidden(isKeyboardVisible || isChoosingDestination)
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

  func handleScroll(_ offset: CGPoint) {
    scrollOffset = offset.y
  }

  private var fadeAmount: Double {
    let offset = min(0, scrollOffset)
    let clamped = max(0, min(1, abs(offset) / 24))
    return clamped
  }

  var filledView: some View {
    ZStack(alignment: .bottom) {
      LinearGradient(
        colors: GradientColors.gradientColors(colorScheme: colorScheme),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      ScrollViewWithOffset(onScroll: handleScroll) {
        LazyVStack(alignment: .leading) {
          ForEach(groupedEntries, id: \.date) { group in
            Text(dateString(for: group.date, entryCount: group.entries.count))
              .font(MorselFont.title)
              .padding()
            ForEach(group.entries) { entry in
              DeletableRow(isDraggingHorizontally: $isDraggingHorizontally) {
                delete(entry: entry)
              } content: {
                MealRow(entry: entry)
                  .frame(minHeight: 44)
              }
              .contentShape(Rectangle())
            }
          }
        }
        .blur(radius: isKeyboardVisible || isChoosingDestination ? 12 : 0)
        .scrollDismissesKeyboard(.immediately)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
          Spacer().frame(height: 160)
        }
        .safeAreaInset(edge: .top) {
          Spacer().frame(height: 24)
        }
      }
      .scrollDisabled(isDraggingHorizontally)
      .scrollIndicators(.hidden)
      .mask(
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.04),
            .init(color: .black, location: 0.83),
            .init(color: .clear, location: 0.895),
            .init(color: .clear, location: 1)
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
      )
      if isChoosingDestination {
        DestinationPicker(
          onPick: { isForMorsel in
            add(entryText, isForMorsel: isForMorsel)
            entryText = ""
            isChoosingDestination = false
          },
          onCancel: {
            entryText = ""
            isChoosingDestination = false
          }
        )
      }
    }
    .scrollDisabled(isKeyboardVisible || isChoosingDestination)
    .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
    .animation(.easeInOut(duration: 0.25), value: isChoosingDestination)
    .ignoresSafeArea(edges: .bottom)
    .onShake {
      // TODO: Add undo here!
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
}

#Preview {
  ContentView(shouldOpenMouth: .constant(false))
    .modelContainer(for: FoodEntry.self, inMemory: true)
}

final class KeyboardObserver: ObservableObject {
  @Published var keyboardHeight: CGFloat = 0

  init() {
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main
    ) { notification in
      guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
      self.keyboardHeight = frame.height
    }
  }
}
