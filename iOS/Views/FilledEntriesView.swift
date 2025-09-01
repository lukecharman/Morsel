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
              DeletableRowView(isDraggingHorizontally: $isDraggingHorizontally) {
                onDelete(entry)
              } content: {
                MealRowView(entry: entry)
                  .frame(minHeight: 44)
                  .transition(.move(edge: .leading).combined(with: .opacity))
              }
              .contentShape(Rectangle())
            }
          }
        }
        // Animate structural changes like insertions
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: entries.map(\.id))
        .scaleEffect(shouldBlurBackground ? 0.98 : 1)
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
      .opacity(shouldHideBackground ? 0.05 : 1)
      .scrollDisabled(isDraggingHorizontally)
      .scrollIndicators(.hidden)
      .mask { mask }
    }
    .ignoresSafeArea(.keyboard)
    .scrollDisabled(shouldBlurBackground)
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

  private var mask: LinearGradient {
    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: .clear, location: 0),
        .init(color: .black, location: 0.03),
        .init(color: .black, location: 0.92),
        .init(color: .clear, location: 0.95),
        .init(color: .clear, location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
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
