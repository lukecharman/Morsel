import SwiftData
import SwiftUI
import WatchConnectivity
import WidgetKit

class PhoneSessionManager: NSObject, WCSessionDelegate, ObservableObject {
  static var shared = PhoneSessionManager()
  
  override init() {
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }
  
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    guard let name = message["name"] as? String else { return }
    guard let idString = message["idString"] as? String else { return }
    guard let id = UUID(uuidString: idString) else { return }
    guard let isForMorselString = message["forMorsel"] as? String else { return }
    guard let isForMorsel = Bool(isForMorselString) else { return }
    guard let origin = message["origin"] as? String else { return }
    
    // We don't want to save an entry that came from the phone if it's bounced to watch and back.
    guard origin != "phone" else { return }
    
    Task {
      await saveMealLocally(name: name, id: id, isForMorsel: isForMorsel, origin: origin)
    }
  }
  
  @MainActor
  func saveMealLocally(name: String, id: UUID, isForMorsel: Bool, origin: String) async {
    do {
      let container: ModelContainer = .morsel
      let context = container.mainContext
      let existingFetch = FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.id == id })

      guard try context.fetch(existingFetch).isEmpty else { return }
      
      try await Adder.add(id: id, name: name, isForMorsel: isForMorsel, context: .phoneFromWatch)
    } catch {
      print("Phone failed to save new meal: \(error)")
    }
  }

  func notifyWatchOfNewColor(_ color: Color) {
    let rgba = UIColor(color).rgba

    let message: [String: Any] = [
      "morselColorRed": rgba[0],
      "morselColorGreen": rgba[1],
      "morselColorBlue": rgba[2],
      "morselColorAlpha": rgba[3],
      "origin": "phone"
    ]

    if WCSession.default.isReachable {
      WCSession.default.sendMessage(message, replyHandler: nil) { error in
        print("Failed to send color to Watch: \(error)")
      }
    }
  }

  func notifyWatchOfNewMeal(name: String, id: UUID, isForMorsel: Bool) {
    if WCSession.default.isReachable {
      let message = [
        "name": name,
        "idString": id.uuidString,
        "forMorsel": isForMorsel.description,
        "origin": "phone"
      ]
      WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
        print("Failed to send meal to Watch: \(error)")
      })
    }
  }

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {}
  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) {}
}
