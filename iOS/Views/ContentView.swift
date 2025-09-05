import CoreData
import CoreMorsel
import CloudKit
import SwiftUI
import SwiftData
import WatchConnectivity
import WidgetKit

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var appSettings: AppSettings
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
  @AppStorage("hasEverAddedEntry") private var hasEverAddedEntry: Bool = false
  @Query(sort: \FoodEntry.timestamp, order: .reverse)

  private var entries: [FoodEntry]

  @State private var widgetReloadWorkItem: DispatchWorkItem?
  @State private var scrollOffset: CGFloat = 0
  @State private var isDraggingHorizontally = false
  @State private var isKeyboardVisible = false
  @State private var keyboardHeight: CGFloat = 0
  @State private var entryText: String = ""
  @State private var isChoosingDestination = false
  @State private var showStats = false
  @State private var showExtras = false
  @State private var showOnboarding = false
  @State private var onboardingPage: Double = 0
  @State private var shouldCloseMouth: Bool = false
  @State private var destinationProximity: CGFloat = 0
  @State private var destinationPickerHeight: CGFloat = 0
  @State private var recentlyDeleted: FoodEntry?
  @State private var showUndoToast = false
  @State private var undoWorkItem: DispatchWorkItem?
  @StateObject private var morselSpeaker = MorselSpeaker()
  @State private var morselAnchor: MorselAnchor? = .init(edge: .bottom, padding: 6)
  private let notificationsManager = NotificationsManager()

  @Binding var shouldOpenMouth: Bool
  @Binding var digestPresentation: DigestPresentation

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
          },
          onDrag: { position in
            withAnimation {
              destinationProximity = position
            }
          }
        )
        .frame(maxHeight: .infinity)
        .ignoresSafeArea()
        .background(
          HeightReader { height in
            destinationPickerHeight = height
          }
        )
      }
    }
    .overlay {
      sidePanelView(alignment: .leading, isVisible: showStats) {
        StatsView(statsModel: StatsModel(modelContainer: .morsel)) {
          // Internal request to show digest with no initial offset
          withAnimation {
            showStats = false
            digestPresentation = .visible(initialOffset: nil)
          }
        }
      }
    }
    .overlay {
      sidePanelView(alignment: .trailing, isVisible: showExtras) {
        ExtrasView() {
          withAnimation {
            showExtras = false
          }
        } onShowWelcome: {
          withAnimation {
            showExtras = false
            showOnboarding = true
          }
        }
      }
    }
    .overlay {
      bottomPanelView(isVisible: showOnboarding) {
        OnboardingView(page: $onboardingPage, onClose: {
          withAnimation {
            showOnboarding = false
          }
          hasSeenOnboarding = true
          notificationsManager.requestNotificationPermissions()
          morselAnchor = .init(edge: .bottom, padding: 6)
        }, onSpeak: { message in
          morselSpeaker.speak(message)
        })
      }
    }
    .overlay {
      // Single digest overlay driven by unified state
      bottomPanelView(isVisible: isDigestVisible) {
        DigestView(
          meals: entries.map {
            Meal(date: $0.timestamp, name: $0.name, type: $0.isForMorsel ? .resisted : .craving)
          },
          initialOffset: currentDigestOffset,
          onClose: {
            withAnimation {
              digestPresentation = .hidden
            }
          }
        )
      }
    }
    .overlay(alignment: .top) { bottomBar }
    .overlay(alignment: .bottom) { morsel }
    .overlay(alignment: .bottom) {
      if showUndoToast {
        UndoToastView {
          undoDelete()
        }
        .padding(.bottom, 120)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
      }
    }
    .onAppear { onAppear() }
    .onReceive(NotificationPublishers.keyboardWillShow) { notification in
      if let height = extractKeyboardHeight(from: notification) {
        withAnimation {
          keyboardHeight = height
          isKeyboardVisible = true
        }
      }
    }
    .onReceive(NotificationPublishers.keyboardWillHide) { _ in
      withAnimation {
        keyboardHeight = 0
        isKeyboardVisible = false
      }
    }
    .onReceive(NotificationPublishers.cloudKitDataChanged) { _ in }
    .onReceive(NotificationPublishers.appDidBecomeActive) { _ in }
    .onChange(of: entries.count) { _, new in updateWidget(newCount: new) }
    .statusBarHidden(shouldBlurBackground || shouldHideBackground)
  }
}

private extension ContentView {
  var isLookingUp: Bool {
    showStats || showExtras
  }

  var isDigestVisible: Bool {
    if case .visible = digestPresentation { return true }
    return false
  }

  var currentDigestOffset: Int? {
    if case let .visible(initialOffset) = digestPresentation { return initialOffset }
    return nil
  }

  var morsel: some View {
    GeometryReader { geo in
      MorselView(
        shouldOpen: _shouldOpenMouth,
        shouldClose: $shouldCloseMouth,
        isChoosingDestination: $isChoosingDestination,
        destinationProximity: $destinationProximity,
        isLookingUp: .constant(isLookingUp),
        isOnboardingVisible: $showOnboarding,
        onboardingPage: $onboardingPage,
        speaker: morselSpeaker,
        anchor: $morselAnchor,
        morselColor: appSettings.morselColor,
        onTap: {
          if showStats { withAnimation { showStats = false } }
          if showExtras { withAnimation { showExtras = false } }
        },
        onAdd: { text in
          entryText = text
          withAnimation { isChoosingDestination = true }
        }
      )
      .frame(width: geo.size.width, height: geo.size.height)
      .offset(y: offsetY(for: geo))
      .animation(.spring(response: 0.4, dampingFraction: 0.8), value: offsetY(for: geo))
    }
  }

  func offsetY(for geometry: GeometryProxy) -> CGFloat {
    if isChoosingDestination {
      return -(destinationPickerHeight / 2 + 40)
    } else if isKeyboardVisible {
      let screenHeight = geometry.size.height
      let availableSpaceAboveKeyboard = screenHeight - keyboardHeight
      let centerOfAvailableSpace = availableSpaceAboveKeyboard / 2
      let currentDefaultPosition = screenHeight / 2
      return centerOfAvailableSpace - currentDefaultPosition
    } else {
      return 0
    }
  }

  @ViewBuilder
  var bottomBar: some View {
    if !isKeyboardVisible && !isChoosingDestination && !showOnboarding && !isDigestVisible {
      BottomBarView(
        showStats: $showStats,
        showExtras: $showExtras,
        isKeyboardVisible: isKeyboardVisible
      )
    }
  }

  var emptyStateView: some View {
    EmptyStateView(
      shouldBlurBackground: shouldBlurBackground,
      shouldHideBackground: shouldHideBackground,
      isFirstLaunch: !hasEverAddedEntry
    ) {
      if shouldBlurBackground {
        shouldOpenMouth = false
        shouldCloseMouth = true
      }
      hasSeenOnboarding = true
      notificationsManager.requestNotificationPermissions()
    }
  }

  var filledView: some View {
    FilledEntriesView(
      entries: entries,
      shouldBlurBackground: shouldBlurBackground,
      shouldHideBackground: shouldHideBackground,
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
      onDelete: delete,
      onToggleDestination: toggleDestination,
      onRename: rename
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
    showStats || showExtras
  }

  var shouldHideBackground: Bool {
    isKeyboardVisible || isChoosingDestination || showOnboarding || isDigestVisible
  }
}

private extension ContentView {
  func handleScroll(_ offset: CGPoint) {
    scrollOffset = offset.y
  }

  func onAppear() {
    if !hasSeenOnboarding {
      showOnboarding = true
    }
    if !entries.isEmpty && !hasEverAddedEntry {
      hasEverAddedEntry = true
    }
    NotificationCenter.default.addObserver(
      forName: NSPersistentCloudKitContainer.eventChangedNotification,
      object: nil,
      queue: OperationQueue.main
    ) { _ in
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

  @MainActor
  func delete(entry: FoodEntry) {
    let backup = FoodEntry(
      name: entry.name,
      timestamp: entry.timestamp,
      isForMorsel: entry.isForMorsel
    )

    withAnimation {
      modelContext.delete(entry)
      try? modelContext.save()

      if entry.isForMorsel {
        Analytics.track(DeleteForMorselEvent(cravingName: entry.name, timestamp: entry.timestamp))
      } else {
        Analytics.track(DeleteForMeEvent(mealName: entry.name, timestamp: entry.timestamp))
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        WidgetCenter.shared.reloadAllTimelines()
      }
    }

    recentlyDeleted = backup
    showUndoToast = true

    undoWorkItem?.cancel()
    let workItem = DispatchWorkItem {
      withAnimation {
        showUndoToast = false
        recentlyDeleted = nil
      }
    }
    undoWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
  }

  @MainActor
  func undoDelete() {
    guard let entry = recentlyDeleted else { return }
    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
      modelContext.insert(entry)
      try? modelContext.save()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      WidgetCenter.shared.reloadAllTimelines()
    }
    recentlyDeleted = nil
    undoWorkItem?.cancel()
    withAnimation {
      showUndoToast = false
    }
  }

  func add(_ entry: String, isForMorsel: Bool) {
    let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    _ = withAnimation {
      Task {
        try await Adder.add(name: trimmed, isForMorsel: isForMorsel, context: .phoneApp)
      }
    }
    hasEverAddedEntry = true
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

  func extractKeyboardHeight(from notification: Notification) -> CGFloat? {
    guard
      let userInfo = notification.userInfo,
      let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
    else {
      return nil
    }
    return frame.height
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
          .transition(.move(edge: alignment == .leading ? .leading : .trailing).combined(with: .blurReplace))
          .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
          .gesture(
            DragGesture()
              .onEnded { value in
                if alignment == .leading && value.translation.width < -40 {
                  withAnimation { showStats = false }
                } else if alignment == .trailing && value.translation.width > 40 {
                  withAnimation { showExtras = false }
                }
              }
          )
      }
    }
  }

  @ViewBuilder
  func bottomPanelView<Content: View>(
    isVisible: Bool,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    ZStack {
      if isVisible {
        Color.black.opacity(0.25)
          .ignoresSafeArea()
        content()
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          .transition(.move(edge: .bottom))
          .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
      }
    }
  }
}

private extension ContentView {
  @MainActor
  func toggleDestination(for entry: FoodEntry) {
    entry.isForMorsel.toggle()
    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
      try? modelContext.save()
    }
    WidgetCenter.shared.reloadAllTimelines()
  }

  @MainActor
  func rename(entry: FoodEntry, newName: String) {
    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, entry.name != trimmed else { return }
    entry.name = trimmed
    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
      try? modelContext.save()
    }
    WidgetCenter.shared.reloadAllTimelines()
  }
}

#Preview {
  ContentView(
    shouldOpenMouth: .constant(false),
    digestPresentation: .constant(.hidden)
  )
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
