import Foundation
import SwiftUI
import WidgetKit

enum Key: String {
  case morselColor
}

class AppSettings: ObservableObject {
  static let shared = AppSettings()
  private let defaults = UserDefaults(suiteName: "group.com.lukecharman.morsel")!

  @Published var morselColor: Color {
    didSet {
      let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(morselColor), requiringSecureCoding: false)
      defaults.set(data, forKey: Key.morselColor.rawValue)
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  private init() {
    if let data = defaults.data(forKey: Key.morselColor.rawValue),
       let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
      _morselColor = Published(initialValue: Color(color))
    } else {
      _morselColor = Published(initialValue: Color.blue)
    }
  }
}
