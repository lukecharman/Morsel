import SwiftUI
import SwiftData
import WidgetKit
import WatchKit

struct WatchContentView: View {
  @Environment(\.modelContext) private var modelContext

  @Query(filter: todayPredicate, sort: \.timestamp, order: .reverse)
  private var todayEntries: [FoodEntry]

  @State private var showingMealPrompt = false
  @State private var mealName = ""
  @State private var saving = false

  static var todayPredicate: Predicate<FoodEntry> {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: Date())
    let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

    return #Predicate<FoodEntry> { entry in
      entry.timestamp >= startOfToday && entry.timestamp < startOfTomorrow
    }
  }

  var body: some View {
    ScrollView {
      if saving {
        ProgressView()
          .progressViewStyle(.circular)
          .scaleEffect(1.5)
          .padding()
      } else {
        MouthAddButton(shouldOpen: $showingMealPrompt, isOpen: .constant(false), onAdd: { _ in })
          .onTapGesture {
            showingMealPrompt = true
          }
      }

      Text("Today’s Meals")
        .font(.title3)
        .bold()
        .padding(.bottom, 4)
      if todayEntries.isEmpty {
        Text("The first snack is the hardest...")
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      } else {
        ForEach(todayEntries) { meal in
          HStack {
            Text(meal.name)
              .font(.body)
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)

            Text(meal.timestamp, format: .dateTime.hour().minute())
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .sheet(isPresented: $showingMealPrompt) {
      mealEntrySheet
    }
  }

  var mealEntrySheet: some View {
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
