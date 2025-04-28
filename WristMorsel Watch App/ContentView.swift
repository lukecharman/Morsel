import SwiftUI
import SwiftData
import WidgetKit
import WatchKit

struct WatchContentView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var showingMealPrompt = false
  @State private var mealName = ""
  @State private var saving = false

  var body: some View {
    VStack {
      if saving {
        ProgressView()
          .progressViewStyle(.circular)
          .scaleEffect(1.5)
          .padding()
      } else {
        Button(action: {
          showingMealPrompt = true
        }) {
          VStack {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 40))
            Text("Log Meal")
              .font(.headline)
          }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      }
    }
    .sheet(isPresented: $showingMealPrompt) {
      VStack {
        Text("What did you eat?")
          .font(.headline)
          .padding()

        TextField("Meal name", text: $mealName)
          .padding()
          .submitLabel(.done)
          .onSubmit {
            saveMeal()
          }

        Button("Save") {
          saveMeal()
        }
        .buttonStyle(.borderedProminent)
        .disabled(mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .padding()

        Spacer()
      }
      .padding()
    }
  }

  private func saveMeal() {
    let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return }

    saving = true
    showingMealPrompt = false

    Task {
      let newEntry = FoodEntry(name: trimmedName, timestamp: Date())
      modelContext.insert(newEntry)

      do {
        try modelContext.save()
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.lukecharman.morsel") {
          print("📂 Watch is saving to: \(appGroupURL.path)")
        }
        print("✅ Meal saved from Watch: \(newEntry.name)")
      } catch {
        print("💥 Failed to save meal from Watch: \(error)")
      }

      WidgetCenter.shared.reloadAllTimelines()

      mealName = ""
      saving = false

      WKInterfaceDevice.current().play(.success)
    }
  }
}

#Preview {
  WatchContentView()
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
