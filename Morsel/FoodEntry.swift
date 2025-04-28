import Foundation
import SwiftData

@Model
final class FoodEntry {
  var id: UUID
  var name: String
  var timestamp: Date

  init(name: String, timestamp: Date = .now) {
    self.id = UUID()
    self.name = name
    self.timestamp = timestamp
  }
}
