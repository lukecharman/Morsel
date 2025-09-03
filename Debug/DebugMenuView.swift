#if DEBUG
import SwiftUI
import CoreMorsel
import SwiftData
import WidgetKit

struct DebugMenuView: View {
  @State private var showStudio = false
  private let notificationsManager = NotificationsManager()
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          CardView(
            title: "",
            value: "Schedule Digest",
            icon: "timer",
            isFirst: true,
            onTap: { notificationsManager.scheduleDebugDigest() }
          )
          CardView(
            title: "",
            value: "Morsel Studio",
            icon: "paintpalette",
            onTap: { showStudio = true }
          )
          CardView(
            title: "",
            value: "Populate",
            icon: "shippingbox.fill",
            onTap: { populateData() }
          )
          CardView(
            title: "",
            value: "Crash",
            icon: "exclamationmark.triangle.fill",
            isLast: true,
            onTap: { let _ = ["A"][3] }
          )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
      }
      .sheet(isPresented: $showStudio) { MorselStudio() }
    }
  }
}

private extension DebugMenuView {
  func populateData() {
    // 1) Clear all current entries
    _ = modelContext.deleteAll(FoodEntry.self)

    // 2) Generate realistic data across ~90 days
    let calendar = Calendar.current
    let daysBack = 90
    let meRatio: Double = 0.7 // 70% Me, 30% Morsel
    let minPerDay = 1
    let maxPerDay = 6

    // A diverse pool of items (meals, snacks, drinks)
    let items: [String] = [
      "Pasta Bolognese", "Chicken Salad", "Avocado Toast", "Yoghurt & Berries", "Granola Bowl",
      "Banana", "Apple", "Orange", "Grapes", "Mixed Nuts",
      "Protein Bar", "Smoothie", "Oat Latte", "Cappuccino", "Americano",
      "Green Tea", "Herbal Tea", "Iced Coffee", "Espresso",
      "Bagel & Cream Cheese", "Egg Sandwich", "Omelette", "Scrambled Eggs",
      "Porridge", "Overnight Oats", "French Toast", "Pancakes",
      "Sushi", "Burrito", "Chicken Wrap", "Tuna Sandwich", "Ham Sandwich",
      "Caesar Salad", "Greek Salad", "Quinoa Bowl", "Rice & Veg",
      "Stir Fry", "Curry & Rice", "Chilli Con Carne", "Pho",
      "Pizza Slice", "Burger", "Fries", "Fish & Chips", "Chicken Wings",
      "Hummus & Pita", "Carrot Sticks", "Celery & Peanut Butter",
      "Crackers & Cheese", "Cheese Toastie", "Tomato Soup", "Minestrone",
      "Chocolate Bar", "Biscuits", "Cake Slice", "Brownie", "Ice Cream",
      "Popcorn", "Crisps", "Pretzels", "Trail Mix", "Rice Cakes",
      "Pistachios", "Almonds", "Cashews", "Peanut Butter Toast",
      "Tuna & Rice", "Chicken & Broccoli", "Steak & Potatoes",
      "Lasagne", "Mac & Cheese", "Ramen", "Gnocchi",
      "Falafel Wrap", "Halloumi Salad", "Feta & Olives", "Couscous",
      "Taco", "Nachos", "Enchiladas", "Quesadilla",
      "Fruit Salad", "Mango Slices", "Pineapple", "Watermelon",
      "Yoghurt Drink", "Kefir", "Protein Shake", "Electrolyte Drink"
    ]

    var allEntries: [FoodEntry] = []
    for dayOffset in 0..<daysBack {
      guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

      // Bias weekdays vs weekends a bit: weekends slightly fewer logs
      let weekday = calendar.component(.weekday, from: date) // 1..7
      let baseCount = Int.random(in: minPerDay...maxPerDay)
      let isWeekend = (weekday == 1 || weekday == 7)
      let todaysCount = max(minPerDay, baseCount - (isWeekend ? 1 : 0))

      for _ in 0..<todaysCount {
        // Random time between 07:00 and 22:30
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = Int.random(in: 7...22)
        comps.minute = Int.random(in: 0...59)
        guard let timestamp = calendar.date(from: comps) else { continue }

        // Realistic name from pool
        let name = items.randomElement() ?? "Snack"

        // 70/30 split for Me vs Morsel
        let isForMorsel = Double.random(in: 0...1) > meRatio

        let entry = FoodEntry(
          name: name,
          timestamp: timestamp,
          isForMorsel: isForMorsel
        )
        allEntries.append(entry)
      }
    }

    // Insert and save in batches for performance
    let batchSize = 500
    var index = 0
    while index < allEntries.count {
      let batch = allEntries[index..<min(index + batchSize, allEntries.count)]
      for entry in batch {
        modelContext.insert(entry)
      }
      try? modelContext.save()
      index += batchSize
    }

    // Refresh widgets
    WidgetCenter.shared.reloadAllTimelines()
  }
}
#endif
