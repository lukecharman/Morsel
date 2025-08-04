import SwiftUI
import SwiftData
import WidgetKit
import WatchKit

struct WatchContentView: View {
  @Environment(\.modelContext) private var modelContext

  @EnvironmentObject private var appSettings: AppSettings

  @Query(filter: todayPredicate, sort: \.timestamp, order: .reverse)
  private var todayEntries: [FoodEntry]

  @State private var showingMealPrompt = false
  @State private var showingDestinationPicker = false
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
        MorselView(
          shouldOpen: .constant(false),
          shouldClose: .constant(false),
          isChoosingDestination: .constant(false),
          destinationProximity: .constant(0),
          isLookingUp: .constant(false),
          morselColor: appSettings.morselColor,
          supportsOpen: false,
          onAdd: { _ in }
        )
        .onTapGesture {
          showingMealPrompt = true
        }
        .offset(y: -12)
        Text("Today")
          .font(MorselFont.widgetTitle)
          .padding(.bottom, 8)
          .offset(y: -8)
        if todayEntries.isEmpty {
          Text("The first snack\nis the hardest...")
            .font(MorselFont.widgetBody)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .offset(y: -12)
            .onAppear {
              Analytics.track(ScreenViewEmptyState())
            }
        } else {
          ForEach(todayEntries) { meal in
            HStack {
              if meal.isForMorsel {
                MonochromeMorsel(width: 16, color: appSettings.morselColor)
              } else {
                Image(systemName: meal.isForMorsel ? "face.smiling.fill" : "person.fill")
                  .frame(width: 16)
                  .font(.footnote)
                  .foregroundStyle(appSettings.morselColor)
              }
              Text(meal.name)
                .font(MorselFont.body)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
              Spacer()
              Text(meal.timestamp, format: .dateTime.hour().minute())
                .font(MorselFont.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
          }
          .offset(y: -12)
          .onAppear {
            Analytics.track(ScreenViewFilledEntries(count: todayEntries.count))
          }
        }
      }
    }
    .sheet(isPresented: $showingMealPrompt) {
      mealEntrySheet
    }
    .sheet(isPresented: $showingDestinationPicker) {
      destinationPickerSheet
    }
  }

  var mealEntrySheet: some View {
    VStack {
      Spacer()
        .frame(height: 12)
      Text("What's cookin'?")
        .font(MorselFont.body)
        .lineLimit(2)
      TextField("...pizza?", text: $mealName)
        .submitLabel(.done)
        .font(MorselFont.body)
        .onSubmit {
          withAnimation {
            showingMealPrompt = false
            showingDestinationPicker = true
          }
        }
      Button("Next") {
        withAnimation {
          showingMealPrompt = false
          showingDestinationPicker = true
        }
      }
      .font(MorselFont.body)
      .buttonStyle(.bordered)
      .disabled(mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      .padding()

      Spacer()
    }
    .padding()
  }

  var destinationPickerSheet: some View {
    VStack {
      MorselView(
        shouldOpen: .constant(false),
        shouldClose: .constant(false),
        isChoosingDestination: .constant(false),
        destinationProximity: .constant(0),
        isLookingUp: .constant(false),
        morselColor: appSettings.morselColor,
        supportsOpen: false,
        onAdd: { _ in }
      )
      Text("Who was it for?")
        .font(MorselFont.body)
        .padding()
      HStack {
        Button("For\nMe") {
          saveMeal(isForMorsel: false)
        }
        .font(MorselFont.body)
        .buttonStyle(.bordered)
        Button("For Morsel") {
          saveMeal(isForMorsel: true)
        }
        .font(MorselFont.body)
        .buttonStyle(.bordered)
      }
      Spacer()
    }
    .padding()
    .onAppear {
      Analytics.track(ScreenViewDestinationPicker())
    }
  }

  private func saveMeal(isForMorsel: Bool) {
    let trimmedName = mealName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return }

    saving = true

    Task {
      await WatchSessionManager.shared.saveMealLocally(
        name: trimmedName,
        id: UUID(),
        isForMorsel: isForMorsel,
        origin: "watch"
      )

      WidgetCenter.shared.reloadAllTimelines()

      mealName = ""
      saving = false

      withAnimation {
        showingMealPrompt = false
        showingDestinationPicker = false
      }

      WKInterfaceDevice.current().play(.success)
    }
  }
}

#Preview {
  WatchContentView()
    .environmentObject(AppSettings.shared)
    .modelContainer(for: FoodEntry.self, inMemory: true)
}
