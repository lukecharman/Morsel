import CoreMorsel
import Foundation
import SwiftUI

struct FilledEntriesView: View {
  let entries: [FoodEntry]
  let shouldBlurBackground: Bool

  @Environment(\.colorScheme) private var colorScheme

  @Binding var scrollOffset: CGFloat
  @Binding var isDraggingHorizontally: Bool

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

            ForEach(group.entries) { entry in
              DeletableRowView(isDraggingHorizontally: $isDraggingHorizontally) {
                onDelete(entry)
              } content: {
                MealRowView(entry: entry)
                  .frame(minHeight: 44)
              }
              .contentShape(Rectangle())
            }
          }
        }
        .opacity(shouldBlurBackground ? 0.06 : 1)
        .scaleEffect(shouldBlurBackground ? CGSize(width: 0.97, height: 0.97) : CGSize(width: 1.0, height: 1.0), anchor: .top)
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
            .init(color: .black, location: 0.03),
            .init(color: .black, location: 0.92),
            .init(color: .clear, location: 0.95),
            .init(color: .clear, location: 1)
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
      )
    }
    .scrollDisabled(shouldBlurBackground)
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
