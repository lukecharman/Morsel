import Foundation

struct Meal {
  enum MealType {
    case normal, craving, resisted
  }

  let date: Date
  let name: String
  let type: MealType
}
