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
  @State private var scrollOffset: CGFloat = 0
  @State private var showStats = false
  @State private var showExtras = false

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
      BottomOverlayBar(
        onStatsTap: { showStats = true },
        onExtrasTap: { showExtras = true },
        onAdd: add,
        shouldOpenMouth: _shouldOpenMouth
      )
    }
    .onAppear {
      loadEntries()
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
    .background(LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom))
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
        colors: gradientColors,
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      ScrollViewWithOffset(onScroll: handleScroll) {
        LazyVStack(alignment: .leading) {
          Section {
            ForEach(groupedEntries, id: \.date) { group in
              Text(dateString(for: group.date, entryCount: group.entries.count))
                .font(MorselFont.title)
                .padding()
              ForEach(group.entries) { entry in
//                DeletableRow {
//                  delete(entry: entry)
//                } content: {
                  MealRow(entry: entry)
//                }
              }
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
      .mask(
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.05),
            .init(color: .black, location: 0.83),
            .init(color: .clear, location: 0.88),
            .init(color: .clear, location: 1)
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
      )

      if showStats {
        //
      }

      if showExtras {
        //
      }
    }
    .ignoresSafeArea(edges: .bottom)
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
        Color.blue.opacity(0.1),
        Color.cyan.opacity(0.1),
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

enum ScrollOffsetNamespace {
  static let namespace = "scrollView"
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGPoint = .zero
  static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

struct ScrollViewOffsetTracker: View {
  var body: some View {
    GeometryReader { geo in
      Color.clear
        .preference(
          key: ScrollOffsetPreferenceKey.self,
          value: geo
            .frame(in: .named(ScrollOffsetNamespace.namespace))
            .origin
        )
    }
    .frame(height: 0)
  }
}

private extension ScrollView {
  func withOffsetTracking(
    action: @escaping (_ offset: CGPoint) -> Void
  ) -> some View {
    self.coordinateSpace(name: ScrollOffsetNamespace.namespace)
      .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
  }
}

struct ScrollViewWithOffset<Content: View>: View {
  public init(
    _ axes: Axis.Set = .vertical,
    showsIndicators: Bool = true,
    onScroll: ScrollAction? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.axes = axes
    self.showsIndicators = showsIndicators
    self.onScroll = onScroll ?? { _ in }
    self.content = content
  }

  private let axes: Axis.Set
  private let showsIndicators: Bool
  private let onScroll: ScrollAction
  private let content: () -> Content

  public typealias ScrollAction = (_ offset: CGPoint) -> Void

  public var body: some View {
    ScrollView(axes, showsIndicators: showsIndicators) {
      ZStack(alignment: .top) {
        ScrollViewOffsetTracker()
        content()
      }
    }.withOffsetTracking(action: onScroll)
  }
}

struct BottomOverlayBar: View {
  var onStatsTap: () -> Void
  var onExtrasTap: () -> Void
  var onAdd: (String) -> Void

  @Binding var shouldOpenMouth: Bool

  @State private var isMouthOpen = false

  var body: some View {
    ZStack {
      // Morsel in the centre
      MouthAddButton(
        shouldOpen: $shouldOpenMouth,
        isOpen: $isMouthOpen,
        onAdd: onAdd
      )

      HStack {
        ZStack {
          Circle()
            .foregroundStyle(Material.bar)
            .frame(width: 44, height: 44)
            .shadow(radius: 8)
          Button(action: onStatsTap) {
            Image(systemName: "chart.bar.xaxis")
              .padding(64)
          }
        }
        Spacer()
      }
      .opacity(isMouthOpen ? 0 : 1)
      .disabled(isMouthOpen)

      HStack {
        Spacer()
        ZStack {
          Circle()
            .foregroundStyle(Material.bar)
            .frame(width: 44, height: 44)
            .shadow(radius: 8)
          Button(action: onExtrasTap) {
            Image(systemName: "ellipsis.circle")
              .padding(64)
          }
        }
      }
      .opacity(isMouthOpen ? 0 : 1)
      .disabled(isMouthOpen)
    }
    .frame(height: 100)
    .padding(.bottom, 16)
  }
}

struct DeletableRow<Content: View>: View {
  let onDelete: () -> Void
  @ViewBuilder let content: () -> Content

  @State private var offset: CGFloat = 0
  @GestureState private var isDragging = false
  @State private var crossedThreshold = false
  @State private var animatePulse = false

  private let deleteThreshold: CGFloat = -80

  var body: some View {
    ZStack {
      content()
        .offset(x: offset)
        .gesture(
          DragGesture()
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged { value in
              offset = min(0, value.translation.width)

              let hasCrossed = offset < deleteThreshold
              if hasCrossed && !crossedThreshold {
                crossedThreshold = true
                triggerPulse()
              } else if !hasCrossed && crossedThreshold {
                crossedThreshold = false
              }
            }
            .onEnded { value in
              if offset < deleteThreshold {
                withAnimation(.easeInOut) {
                  onDelete()
                }
              } else {
                withAnimation(.spring()) {
                  offset = 0
                }
              }
            }
        )

      // Trash icon
      HStack {
        Spacer()
        Image(systemName: "trash")
          .foregroundColor(.red)
          .padding(.trailing, 16)
          .scaleEffect(animatePulse ? 1.4 : 1.0)
          .opacity(trashIconOpacity)
          .offset(x: trashIconOffset)
          .animation(.easeOut(duration: 0.2), value: offset)
      }
    }
  }

  private func triggerPulse() {
    animatePulse = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      animatePulse = false
    }
  }

  private var trashIconOpacity: Double {
    let threshold: CGFloat = -20
    return offset < threshold ? Double(min(abs(offset + threshold) / 40, 1)) : 0
  }

  private var trashIconOffset: CGFloat {
    return max(0, 40 + offset * 0.5)
  }
}
