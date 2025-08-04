@testable import CoreMorsel
import SwiftUI
import Testing

@MainActor
struct AppSettingsTests {
  @Test func savesColorToUserDefaults() async throws {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)
    let settings = AppSettings.shared
    let originalColor = settings.morselColor
    defer {
      settings.morselColor = originalColor
      defaults?.removeObject(forKey: Key.morselColorRGBA.rawValue)
      defaults?.removeObject(forKey: Key.morselColor.rawValue)
    }

    settings.morselColor = .red
    let rgba = defaults?.array(forKey: Key.morselColorRGBA.rawValue) as? [Double]
    #expect(rgba == [1, 0, 0, 1])
  }

  @Test func persistsAppTheme() async throws {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)
    let settings = AppSettings.shared
    let originalTheme = settings.appTheme
    defer {
      settings.appTheme = originalTheme
      defaults?.removeObject(forKey: Key.appTheme.rawValue)
    }

    settings.appTheme = .dark
    let stored = defaults?.string(forKey: Key.appTheme.rawValue)
    #expect(stored == AppTheme.dark.rawValue)
  }

  @Test func invokesColorChangeCallback() async throws {
    let settings = AppSettings.shared
    let originalColor = settings.morselColor
    defer { settings.morselColor = originalColor }

    var called = false
    settings.onMorselColorChange = { _ in called = true }
    settings.morselColor = .green
    #expect(called)
  }
}
