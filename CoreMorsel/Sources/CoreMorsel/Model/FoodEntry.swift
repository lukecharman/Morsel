import Foundation
import SwiftData

@Model
public final class FoodEntry {
  public var id: UUID = UUID()
  public var name: String = ""
  public var timestamp: Date = Date()
  public var isForMorsel: Bool = false

  public init(
    id: UUID = UUID(),
    name: String,
    timestamp: Date = Date(),
    isForMorsel: Bool = false
  ) {
    self.id = id
    self.name = name
    self.timestamp = timestamp
    self.isForMorsel = isForMorsel
  }
}
