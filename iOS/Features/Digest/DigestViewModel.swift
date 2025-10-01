import CoreMorsel
import Foundation
import SwiftUI

final class DigestViewModel: ObservableObject {
  // Inputs
  let meals: [FoodEntry]

  private let weekBuilder: DigestWeekBuilder
  private let modelBuilder: DigestModelBuilder

  // UI state
  @Published var currentPageIndex: Int = 0

  init(
    meals: [FoodEntry],
    weekBuilder: DigestWeekBuilder,
    modelBuilder: DigestModelBuilder
  ) {
    self.meals = meals
    self.weekBuilder = weekBuilder
    self.modelBuilder = modelBuilder
  }
  
  convenience init(meals: [FoodEntry]) {
    let weekBuilder = DigestWeekBuilder()
    let modelBuilder = DigestModelBuilder(meals: meals)

    self.init(
      meals: meals,
      weekBuilder: weekBuilder,
      modelBuilder: modelBuilder
    )
  }

  // MARK: - Paging / Data

  var availableOffsets: [Int] {
    weekBuilder.availableOffsets(for: meals)
  }

  func digest(at offset: Int) -> DigestModel {
    modelBuilder.digest(at: offset)
  }
}
