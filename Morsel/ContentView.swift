import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \FoodEntry.timestamp, order: .reverse) private var entries: [FoodEntry]

  @State private var widgetReloadWorkItem: DispatchWorkItem?

  var body: some View {
    NavigationStack {
      List {
        ForEach(entries) { entry in
          VStack(alignment: .leading) {
            Text(entry.name)
              .font(.body)
            Text(entry.timestamp, format: .dateTime.hour().minute())
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 4)
        }
        .onDelete(perform: deleteEntries)
      }
      .navigationTitle("Today")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          EditButton()
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          NavigationLink(destination: AddEntryView()) {
            Label("Add Entry", systemImage: "plus")
          }
        }
      }
      .onChange(of: entries.count) { _, new in updateWidget(newCount: new) }
    }
  }

  private func updateWidget(newCount: Int) {
    widgetReloadWorkItem?.cancel()

    let workItem = DispatchWorkItem {
      WidgetCenter.shared.reloadAllTimelines()
    }
    widgetReloadWorkItem = workItem

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
  }

  private func deleteEntries(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        modelContext.delete(entries[index])
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        WidgetCenter.shared.reloadAllTimelines()
        print("🗑️ Widget reload after deletion")
      }
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
