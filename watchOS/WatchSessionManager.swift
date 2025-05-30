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
    // Handle morselColor sync from phone
    if let r = message["morselColorRed"] as? Double,
       let g = message["morselColorGreen"] as? Double,
       let b = message["morselColorBlue"] as? Double,
       let a = message["morselColorAlpha"] as? Double,
       let origin = message["origin"] as? String, origin == "phone" {

      let rgba = [r, g, b, a]
      UserDefaults(suiteName: "group.com.lukecharman.morsel")?.set(rgba, forKey: "morselColorRGBA")
      // Notify listeners (e.g., AppSettings) that color was updated
      DispatchQueue.main.async {
        NotificationCenter.default.post(name: .didReceiveMorselColor, object: nil)
      }
      return
    }
    guard let name = message["name"] as? String else { return }
    guard let idString = message["idString"] as? String else { return }
    guard let id = UUID(uuidString: idString) else { return }
    guard let isForMorselString = message["forMorsel"] as? String else { return }
    guard let isForMorsel = Bool(isForMorselString) else { return }
    guard let origin = message["origin"] as? String else { return }

    // We don't want to save an entry that came from the watch if it's bounced to phone and back.
    guard origin != "watch" else { return }

    Task {
      await saveMealLocally(name: name, id: id, isForMorsel: isForMorsel, origin: origin)
    }
  }

  @MainActor
  func saveMealLocally(name: String, id: UUID, isForMorsel: Bool, origin: String) async {
    do {
      let container: ModelContainer = .sharedContainer
      let context = container.mainContext
      let existingFetch = FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.id == id })

      guard try context.fetch(existingFetch).isEmpty else { return }

      try await Adder.add(id: id, name: name, isForMorsel: isForMorsel, context: .watchFromPhone)
    } catch {
      print("Watch failed to save new meal: \(error)")
    }
  }

  func notifyPhoneOfNewMeal(name: String, id: UUID, isForMorsel: Bool) {
    if WCSession.default.isReachable {
      let message = [
        "name": name,
        "idString": id.uuidString,
        "forMorsel": isForMorsel.description,
        "origin": "watch"
      ]
      WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
        print("Failed to send meal to Phone: \(error)")
      })
    }
  }

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {}
}

extension Notification.Name {
  static let didReceiveMorselColor = Notification.Name("didReceiveMorselColor")
}
