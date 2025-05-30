import Foundation
import SwiftUI
import WatchConnectivity
import WidgetKit

enum Key: String {
  case morselColor
}

class AppSettings: ObservableObject {
  static let shared = AppSettings()
  private let defaults = UserDefaults(suiteName: "group.com.lukecharman.morsel")!

  @Published var showDigest = false

  @Published var morselColor: Color {
    didSet {
      let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(morselColor), requiringSecureCoding: false)
      defaults.set(data, forKey: Key.morselColor.rawValue)
      WidgetCenter.shared.reloadAllTimelines()

      let uiColor = UIColor(morselColor)
      var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
      uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

      let message: [String: Any] = [
        "morselColorRed": Double(r),
        "morselColorGreen": Double(g),
        "morselColorBlue": Double(b),
        "morselColorAlpha": Double(a),
        "origin": "phone"
      ]

      if WCSession.default.isReachable {
        WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
          print("Failed to send color to Watch: \(error)")
        })
      }
    }
  }

  private init() {
    #if os(watchOS)
    if let rgba = defaults.array(forKey: "morselColorRGBA") as? [Double], rgba.count == 4 {
      _morselColor = Published(initialValue: Color(.sRGB, red: rgba[0], green: rgba[1], blue: rgba[2], opacity: rgba[3]))
    } else if let data = defaults.data(forKey: Key.morselColor.rawValue),
              let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
      _morselColor = Published(initialValue: Color(color))
    } else {
      _morselColor = Published(initialValue: Color.blue)
    }

    NotificationCenter.default.addObserver(forName: .didReceiveMorselColor, object: nil, queue: .main) { [weak self] _ in
      if let rgba = self?.defaults.array(forKey: "morselColorRGBA") as? [Double], rgba.count == 4 {
        self?.morselColor = Color(.sRGB, red: rgba[0], green: rgba[1], blue: rgba[2], opacity: rgba[3])
      }
    }
    #else
    if let data = defaults.data(forKey: Key.morselColor.rawValue),
       let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
      _morselColor = Published(initialValue: Color(color))
    } else {
      _morselColor = Published(initialValue: Color.blue)
    }
    #endif
  }
}
