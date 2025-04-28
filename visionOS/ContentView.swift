import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \FoodEntry.timestamp, order: .reverse) private var entries: [FoodEntry]

  @State private var showingAddSheet = false

  var body: some View {
    NavigationStack {
      List {
        ForEach(entries) { entry in
          VStack(alignment: .leading) {
            Text(entry.name)
              .font(.title2)
              .fontWeight(.medium)
            Text(entry.timestamp, format: .dateTime.hour().minute())
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 6)
        }
      }
      .navigationTitle("Morsel")
      .glassBackgroundEffect()
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: {
            showingAddSheet = true
          }) {
            Label("Add Meal", systemImage: "plus")
          }
        }
      }
    }
    .sheet(isPresented: $showingAddSheet) {
      AddMealSheet()
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
