import CoreMorsel
import SwiftUI
import UIKit

@MainActor
final class OverlayController {
  static let shared = OverlayController()
  private var window: UIWindow?

  func show() {
    guard window == nil else { return }
    let overlayWindow = UIWindow(frame: UIScreen.main.bounds)
    overlayWindow.windowLevel = .alert + 1
    overlayWindow.rootViewController = UIHostingController(rootView: OverlayMorselView())
    overlayWindow.isHidden = false
    window = overlayWindow
  }

  func hide() {
    window?.isHidden = true
    window = nil
  }
}

private struct OverlayMorselView: View {
  @ObservedObject private var appSettings = AppSettings.shared
  @State private var shouldOpen = false
  @State private var shouldClose = false
  @State private var isChoosingDestination = false
  @State private var destinationProximity: CGFloat = 0
  @State private var isLookingUp = false

  var body: some View {
    MorselView(
      shouldOpen: $shouldOpen,
      shouldClose: $shouldClose,
      isChoosingDestination: $isChoosingDestination,
      destinationProximity: $destinationProximity,
      isLookingUp: $isLookingUp,
      morselColor: appSettings.morselColor,
      onTap: {},
      onAdd: { _ in }
    )
    .environmentObject(appSettings)
    .allowsHitTesting(false)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }
}

