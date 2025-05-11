import SwiftUI

struct FoodEntrySnapshot: Identifiable, Codable {
  var id: UUID = UUID()
  var name: String
  var timestamp: Date = Date()
  var isForMorsel: Bool = false
}
