import SwiftUI
import UIKit

struct ShakeDetector: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> ShakeDetectorViewController {
    ShakeDetectorViewController()
  }

  func updateUIViewController(_ uiViewController: ShakeDetectorViewController, context: Context) {}
}

class ShakeDetectorViewController: UIViewController {
  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    super.motionEnded(motion, with: event)

    if motion == .motionShake {
      NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
    }
  }
}

extension View {
  func onShake(perform action: @escaping () -> Void) -> some View {
    self
      .background(ShakeDetector())
      .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
        action()
      }
  }
}
