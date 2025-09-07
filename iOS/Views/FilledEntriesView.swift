import CoreMorsel
import Foundation
import SwiftUI

struct FilledEntriesView: View {
  let entries: [FoodEntry]
  let shouldBlurBackground: Bool
  let shouldHideBackground: Bool

  @Environment(\.colorScheme) private var colorScheme

  @Binding var scrollOffset: CGFloat
  @Binding var isDraggingHorizontally: Bool
  @Binding var isChoosingDestination: Bool
  @Binding var entryText: String

  let onTap: () -> Void
  let onScroll: (CGPoint) -> Void
  let onDelete: (FoodEntry) -> Void
  let onToggleDestination: (FoodEntry) -> Void
  let onRename: (FoodEntry, String) -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      BackgroundGradientView()
      ScrollViewWithOffset(onScroll: onScroll) {
        LazyVStack(alignment: .leading) {
          ForEach(groupedEntries, id: \.date) { group in
            Text(dateString(for: group.date, entryCount: group.entries.count))
              .font(MorselFont.title)
              .padding()
              .contentTransition(.numericText())

            ForEach(group.entries) { entry in
              MealRowView(
                entry: entry,
                onDelete: { onDelete(entry) },
                onToggle: { onToggleDestination(entry) },
                onRename: { newName in onRename(entry, newName) }
              )
              .frame(minHeight: 44)
              .transition(.move(edge: .leading).combined(with: .opacity))
              .contentShape(Rectangle())
            }
          }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: entries.map(\.id))
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
      .scaleEffect(shouldBlurBackground || shouldHideBackground ? 0.98 : 1)
      .opacity(shouldBlurBackground ? 0.9 : (shouldHideBackground ? 0.05 : 1))
      .blur(radius: shouldBlurBackground ? 2 : 0)
      .scrollDisabled(isDraggingHorizontally)
      .scrollIndicators(.hidden)
      .mask(EdgeFadeMask())
    }
    .ignoresSafeArea(.keyboard)
    .scrollDisabled(shouldBlurBackground || shouldHideBackground)
    .animation(.easeInOut(duration: 0.25), value: isChoosingDestination)
    .onAppear {
      Analytics.track(ScreenViewFilledEntries(count: entries.count))
    }
    .simultaneousGesture(
      TapGesture()
        .onEnded{ _ in
          if shouldBlurBackground {
            onTap()
          }
        }
    )
    .simultaneousGesture(
      DragGesture()
        .onChanged { value in
          if shouldBlurBackground && value.translation.height > 0 {
            onTap()
          }
        }
    )
  }

  private var groupedEntries: [(date: Date, entries: [FoodEntry])] {
    Dictionary(grouping: entries) { entry in
      Calendar.current.startOfDay(for: entry.timestamp)
    }
    .map { (key, value) in (date: key, entries: value) }
    .sorted { $0.date > $1.date }
  }

  private func dateString(for date: Date, entryCount: Int) -> String {
    if Calendar.current.isDateInToday(date) {
      return "Today (\(entryCount))"
    } else if Calendar.current.isDateInYesterday(date) {
      return "Yesterday (\(entryCount))"
    } else {
      let formatted = date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
      return "\(formatted) (\(entryCount))"
    }
  }
}
