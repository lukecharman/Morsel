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
        ForEach(entries) { entry in
          VStack(alignment: .leading) {
            Text(entry.name)
              .font(.headline)
            Text(entry.timestamp, format: .dateTime.hour().minute())
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .onDelete(perform: deleteEntries)
      }
      .overlay(alignment: .bottom) {
//        StaticMorsel()
        MouthAddButton(shouldOpen: _shouldOpenMouth) { entry in
          add(entry)
        }
      }
      .navigationTitle("Morsel")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            showingAddMeal.toggle()
          } label: {
            Label("Add Meal", systemImage: "plus")
          }
        }
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
}

#Preview {
  ContentView(shouldOpenMouth: .constant(false))
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
