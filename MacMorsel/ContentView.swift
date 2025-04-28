import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \FoodEntry.timestamp, order: .reverse) private var entries: [FoodEntry]

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
      .sheet(isPresented: $showingAddMeal) {
        VStack {
          TextField("Meal name", text: $newMealName)
            .textFieldStyle(.roundedBorder)
            .padding()

          Button("Save") {
            addMeal()
          }
          .disabled(newMealName.trimmingCharacters(in: .whitespaces).isEmpty)
          .padding()

          Spacer()
        }
        .padding()
        .frame(width: 300, height: 200)
      }
    }
  }

  private func addMeal() {
    let newEntry = FoodEntry(name: newMealName)
    modelContext.insert(newEntry)
    newMealName = ""
    showingAddMeal = false
  }

  private func deleteEntries(offsets: IndexSet) {
    for index in offsets {
      modelContext.delete(entries[index])
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
