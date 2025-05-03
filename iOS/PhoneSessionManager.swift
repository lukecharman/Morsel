import SwiftData
import WatchConnectivity

class PhoneSessionManager: NSObject, ObservableObject {
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {}
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) {}
  
  override init() {
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }
}

extension PhoneSessionManager: WCSessionDelegate {
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    if let mealName = message["newMealName"] as? String,
       let mealIDString = message["newMealID"] as? String,
       let mealID = UUID(uuidString: mealIDString) {

      Task {
        await saveMealLocally(name: mealName, id: mealID)
      }
    }
  }

  @MainActor
  private func saveMealLocally(name: String, id: UUID) async {
    do {
      let container: ModelContainer = .sharedContainer
      let context = container.mainContext

      let existingFetch = FetchDescriptor<FoodEntry>(
        predicate: #Predicate { $0.id == id }
      )

      let existing = try context.fetch(existingFetch)

      if !existing.isEmpty {
        return
      }

      let newEntry = FoodEntry(id: id, name: name, timestamp: Date())
      context.insert(newEntry)
      try context.save()
    } catch {
      print("Phone failed to save new meal: \(error)")
    }
  }
}
