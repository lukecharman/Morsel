import Foundation
import SwiftUI

struct FilledEntriesView: View {
  let entries: [FoodEntry]
  let shouldBlurBackground: Bool

  @Environment(\.colorScheme) private var colorScheme

  @Binding var scrollOffset: CGFloat
  @Binding var isDraggingHorizontally: Bool
  @Binding var isChoosingDestination: Bool
  @Binding var entryText: String

  let onScroll: (CGPoint) -> Void
  let onAdd: (String, Bool) -> Void
  let onDelete: (FoodEntry) -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      LinearGradient(
        colors: GradientColors.gradientColors(colorScheme: colorScheme),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      ScrollViewWithOffset(onScroll: onScroll) {
        LazyVStack(alignment: .leading) {
          ForEach(groupedEntries, id: \.date) { group in
            Text(dateString(for: group.date, entryCount: group.entries.count))
              .font(MorselFont.title)
              .padding()

            ForEach(group.entries) { entry in
              DeletableRow(isDraggingHorizontally: $isDraggingHorizontally) {
                onDelete(entry)
              } content: {
                MealRow(entry: entry)
                  .frame(minHeight: 44)
              }
              .contentShape(Rectangle())
            }
          }
        }
        .opacity(shouldBlurBackground ? 0.06 : 1)
        .scaleEffect(shouldBlurBackground ? CGSize(width: 0.97, height: 0.97) : CGSize(width: 1.0, height: 1.0))
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
            onAdd(entryText, isForMorsel)
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
    .scrollDisabled(shouldBlurBackground)
    .animation(.easeInOut(duration: 0.25), value: isChoosingDestination)
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
