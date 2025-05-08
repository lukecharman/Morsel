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
          .padding()
      } else {
        StaticMorsel()
          .onTapGesture {
            showingMealPrompt = true
          }
      }

      Text("Today’s Morsels")
        .font(MorselFont.widgetTitle)
        .bold()
        .padding(.bottom, 4)
      if todayEntries.isEmpty {
        Text("The first snack is the hardest...")
          .font(MorselFont.widgetBody)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      } else {
        ForEach(todayEntries) { meal in
          HStack {
            Text(meal.name)
              .font(MorselFont.widgetBody)
              .lineLimit(1)
              .frame(maxWidth: .infinity, alignment: .leading)

            Text(meal.timestamp, format: .dateTime.hour().minute())
              .font(MorselFont.caption)
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
      await WatchSessionManager.shared.saveMealLocally(
        name: trimmedName,
        id: UUID(),
        origin: "watch"
      )

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
