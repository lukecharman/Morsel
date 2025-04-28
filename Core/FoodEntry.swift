import Foundation
import SwiftData

@Model
final class FoodEntry {
  var id: UUID = UUID()
  var name: String = ""
  var timestamp: Date = Date()

  init(id: UUID = UUID(), name: String, timestamp: Date = Date()) {
    self.id = id
    self.name = name
    self.timestamp = timestamp
  }
}
