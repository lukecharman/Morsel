import Foundation
import SwiftUI

enum Key: String {
  case morselColor
}

class AppSettings {
  static let shared = AppSettings()
  private let defaults = UserDefaults(suiteName: "group.com.lukecharman.morsel")!

  var morselColor: UIColor {
    get {
      guard let data = defaults.data(forKey: Key.morselColor.rawValue) else {
        return .blue
      }
      guard let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
        return .blue
      }

      return color
    }
    set {
      let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
      defaults.set(data, forKey: Key.morselColor.rawValue)
    }
  }
}
