import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext

  @Binding var shouldOpenMouth: Bool

  @State private var entries: [FoodEntry] = []
  @State private var showingAddMeal = false
  @State private var newMealName = ""

  var body: some View {
    NavigationStack {
      List {
        ForEach(groupedEntries, id: \.date) { group in
          Section(header: Text(dateString(for: group.date, entryCount: group.entries.count))) {
            ForEach(group.entries) { entry in
              MealRow(entry: entry)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteEntries)
          }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
      }
      .scrollIndicators(.hidden)
      .safeAreaInset(edge: .bottom) {
        Spacer().frame(height: 160)
      }
      .overlay(alignment: .bottom) {
        MouthAddButton(shouldOpen: _shouldOpenMouth) { entry in
          add(entry)
        }
      }
      .onAppear {
        addFakeEntry(daysAgo: 1, name: "Cheese")
        addFakeEntry(daysAgo: 1, name: "Ham")
        addFakeEntry(daysAgo: 1, name: "Eggs")
        addFakeEntry(daysAgo: 2, name: "Sausages")

        loadEntries()
      }
      .navigationTitle("What I've Eaten")
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

  private var groupedEntries: [(date: Date, entries: [FoodEntry])] {
    Dictionary(grouping: entries) { entry in
      Calendar.current.startOfDay(for: entry.timestamp)
    }
    .map { (key, value) in
      (date: key, entries: value)
    }
    .sorted { $0.date > $1.date }
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

  private func deleteEntries(offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(entries[index])
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

  private func addFakeEntry(daysAgo: Int, name: String) {
    let calendar = Calendar.current
    guard let fakeDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return }

    let fakeEntry = FoodEntry(name: name, timestamp: fakeDate)
    modelContext.insert(fakeEntry)
  }
}

#Preview {
  ContentView(shouldOpenMouth: .constant(false))
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
