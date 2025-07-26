import Foundation
import SwiftUI
import WatchConnectivity
import WidgetKit

enum Key: String {
  case morselColor
  case morselColorRGBA
  case appTheme
}

enum AppTheme: String, CaseIterable {
  case system = "system"
  case light = "light"
  case dark = "dark"
  
  var displayName: String {
    switch self {
    case .system: return "System"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }
  
  var colorScheme: ColorScheme? {
    switch self {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}

class AppSettings: ObservableObject {
  static let shared = AppSettings()
  private let defaults = UserDefaults(suiteName: appGroupIdentifier)

  private static let fallbackColor: Color = .blue

  @Published var showDigest = false

  @Published var appTheme: AppTheme {
    didSet {
      defaults?.set(appTheme.rawValue, forKey: Key.appTheme.rawValue)
    }
  }

  @Published var morselColor: Color {
    didSet {
      saveColorToUserDefaults(morselColor)
      WidgetCenter.shared.reloadAllTimelines()
#if os(iOS)
      PhoneSessionManager.shared.notifyWatchOfNewColor(morselColor)
#endif
    }
  }

  private init() {
    let initialColor = AppSettings.loadInitialColor(from: defaults)
    let initialTheme = AppTheme(rawValue: defaults?.string(forKey: Key.appTheme.rawValue) ?? "") ?? .system
    
    _morselColor = Published(initialValue: initialColor)
    _appTheme = Published(initialValue: initialTheme)

#if os(watchOS)
    NotificationCenter.default.addObserver(forName: .didReceiveMorselColor, object: nil, queue: .main) { [weak self] _ in
      self?.morselColor = Self.loadRGBAColor(from: Self.shared.defaults) ?? AppSettings.fallbackColor
    }
#endif
  }

}

private extension AppSettings {
  static func loadInitialColor(from defaults: UserDefaults?) -> Color {
#if os(watchOS)
    return loadRGBAColor(from: defaults) ?? loadArchivedColor(from: defaults) ?? Self.fallbackColor
#else
    return loadArchivedColor(from: defaults) ?? Self.fallbackColor
#endif
  }

  static func loadArchivedColor(from defaults: UserDefaults?) -> Color? {
    guard let data = defaults?.data(forKey: Key.morselColor.rawValue) else { return nil }
    guard let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else { return nil }

    return Color(uiColor)
  }

  static func loadRGBAColor(from defaults: UserDefaults?) -> Color? {
    guard let rgba = defaults?.array(forKey: Key.morselColorRGBA.rawValue) as? [Double], rgba.count == 4 else { return nil }
    return Color(.sRGB, red: rgba[0], green: rgba[1], blue: rgba[2], opacity: rgba[3])
  }

  func saveColorToUserDefaults(_ color: Color) {
    let uiColor = UIColor(color)
    let rgba = uiColor.rgba
    defaults?.set(rgba, forKey: Key.morselColorRGBA.rawValue)

    if let data = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
      defaults?.set(data, forKey: Key.morselColor.rawValue)
    }
  }
}
