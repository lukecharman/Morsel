import UIKit

struct Haptics {
  static let shared = Haptics()

  enum HapticType {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
    case level(Int)
  }

  private let impactLight = UIImpactFeedbackGenerator(style: .light)
  private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
  private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
  private let selection = UISelectionFeedbackGenerator()
  private let notification = UINotificationFeedbackGenerator()

  static func trigger(_ type: HapticType) {
    switch type {
    case .light:
      Self.shared.impactLight.impactOccurred()
      Self.shared.impactLight.prepare()
    case .medium:
      Self.shared.impactMedium.impactOccurred()
      Self.shared.impactMedium.prepare()
    case .heavy:
      Self.shared.impactHeavy.impactOccurred()
      Self.shared.impactHeavy.prepare()
    case .selection:
      Self.shared.selection.selectionChanged()
      Self.shared.selection.prepare()
    case .success:
      Self.shared.notification.notificationOccurred(.success)
      Self.shared.notification.prepare()
    case .warning:
      Self.shared.notification.notificationOccurred(.warning)
      Self.shared.notification.prepare()
    case .error:
      Self.shared.notification.notificationOccurred(.error)
      Self.shared.notification.prepare()
    case .level(let level):
      let clampedLevel = max(0, min(5, level))
      let intensity = CGFloat(clampedLevel + 1) / 6.0
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.prepare()
      generator.impactOccurred(intensity: intensity)
    }
  }

  static func prepare(_ type: HapticType) {
    switch type {
    case .light:
      Self.shared.impactLight.prepare()
    case .medium:
      Self.shared.impactMedium.prepare()
    case .heavy:
      Self.shared.impactHeavy.prepare()
    case .selection:
      Self.shared.selection.prepare()
    case .success, .warning, .error:
      Self.shared.notification.prepare()
    case .level(_):
      // no-op: new generator used each time
      break
    }
  }
}
