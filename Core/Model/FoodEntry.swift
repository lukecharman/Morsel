import Foundation
import SwiftData

@Model
final class FoodEntry {
  var id: UUID = UUID()
  var name: String = ""
  var timestamp: Date = Date()
  var isForMorsel: Bool = false

  init(id: UUID = UUID(), name: String, timestamp: Date = Date(), isForMorsel: Bool = false) {
    self.id = id
    self.name = name
    self.timestamp = timestamp
    self.isForMorsel = isForMorsel
  }
}
