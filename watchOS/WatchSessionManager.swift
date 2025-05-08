import Foundation
import SwiftData
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
  static var shared = WatchSessionManager()

  override init() {
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    guard let mealName = message["newMealName"] as? String,
          let mealIDString = message["newMealID"] as? String,
          let mealID = UUID(uuidString: mealIDString),
          let origin = message["origin"] as? String else {
      return
    }
    guard origin != "watch" else { return }

    Task {
      await saveMealLocally(name: mealName, id: mealID, origin: origin)
    }
  }

  @MainActor
  func saveMealLocally(name: String, id: UUID, origin: String) async {
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

      let newEntry = FoodEntry(id: id, name: name)
      context.insert(newEntry)
      try context.save()

      if origin == "watch" {
        notifyPhoneOfNewMeal(name: name, id: id)
      }
    } catch {
      print("Failed to save meal: \(error)")
    }
  }

  func notifyPhoneOfNewMeal(name: String, id: UUID) {
    if WCSession.default.isReachable {
      let message = [
        "newMealName": name,
        "newMealID": id.uuidString,
        "origin": "watch"
      ]
      WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
        print("Failed to send meal to Phone: \(error)")
      })
    }
  }

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {}
}
