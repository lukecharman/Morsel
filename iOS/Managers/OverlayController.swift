import CoreMorsel
import SwiftUI
import UIKit

@MainActor
final class OverlayController {
  static let shared = OverlayController()
  private var window: SelectiveHitWindow?
  private weak var host: UIHostingController<OverlayMorselView>?

  func show(in windowScene: UIWindowScene) {
    guard window == nil else { return }

    let w = SelectiveHitWindow(windowScene: windowScene)
    w.frame = windowScene.screen.bounds
    w.windowLevel = .alert + 1
    w.backgroundColor = .clear

    let host = UIHostingController(rootView: OverlayMorselView())
    host.view.backgroundColor = .clear
    w.rootViewController = host

    w.isHidden = false
    w.makeKeyAndVisible()          // must be key to receive touches
    self.window = w
    self.host = host
  }

  func updateInteractiveRect(_ rectInWindow: CGRect?) {
    guard let w = window else { return }
    if let r = rectInWindow, !r.isNull, !r.isEmpty {
      w.interactivePath = UIBezierPath(rect: r)
    } else {
      w.interactivePath = .init() // pass-through everywhere
    }
  }

  // If you ever want a non-rect shape:
  func updateInteractivePath(_ pathInWindow: UIBezierPath?) {
    window?.interactivePath = pathInWindow ?? .init()
  }

  func hide() {
    window?.isHidden = true
    window?.rootViewController = nil
    window = nil
    host = nil
  }
}

struct WindowFrameReporter: UIViewRepresentable {
  let onChange: (CGRect?) -> Void

  func makeUIView(context: Context) -> UIView {
    let v = UIView(frame: .zero)
    v.isUserInteractionEnabled = false
    v.backgroundColor = .clear
    return v
  }

  func updateUIView(_ view: UIView, context: Context) {
    // Defer to next runloop so layout is final.
    DispatchQueue.main.async {
      guard let window = view.window else {
        onChange(nil)
        return
      }
      // Convert the reporter's bounds into window coordinates.
      let frameInWindow = view.convert(view.bounds, to: window)
      onChange(frameInWindow)
    }
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
    // Full-screen layout, mascot pinned bottom
    MorselView(
      shouldOpen: $shouldOpen,
      shouldClose: $shouldClose,
      isChoosingDestination: $isChoosingDestination,
      destinationProximity: $destinationProximity,
      isLookingUp: $isLookingUp,
      morselColor: appSettings.morselColor,
      onTap: { /* mascot tap */ },
      onAdd: { _ in }
    )
    .environmentObject(appSettings)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    // Ensure only the mascot is hittable; everything else passes through
    .background(
      // Place the reporter exactly where the mascot actually draws.
      // If MorselView has an internal container for the tappable area,
      // attach the reporter *inside* that container instead.
      WindowFrameReporter { rectInWindow in
        OverlayController.shared.updateInteractiveRect(rectInWindow)
      }
      .frame(width: 1, height: 1) // tiny; just needs to share the same parent
      .allowsHitTesting(false)
      , alignment: .bottom // align with the mascot
    )
  }
}
final class SelectiveHitWindow: UIWindow {
  /// Window-space hit area. If empty, everything passes through.
  var interactivePath: UIBezierPath = .init()

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    interactivePath.contains(point)
  }

  // Optional: allow hardware keyboard to stay with underlying window.
  override var canBecomeKey: Bool { true }
}
