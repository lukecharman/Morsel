import CoreMorsel
import SwiftUI
import UIKit

@MainActor
final class OverlayController {
  static let shared = OverlayController()
  private var window: SelectiveHitWindow?
  private weak var host: UIHostingController<OverlayMorselView>?
  private var configuration: MorselConfiguration = .empty

  func show(in windowScene: UIWindowScene) {
    guard window == nil else { return }

    let w = SelectiveHitWindow(windowScene: windowScene)
    w.frame = windowScene.screen.bounds
    w.windowLevel = .alert + 1
    w.backgroundColor = .clear

    let host = UIHostingController(rootView: OverlayMorselView(configuration: configuration))
    host.view.backgroundColor = .clear
    w.rootViewController = host

    w.isHidden = false
    w.makeKeyAndVisible()          // must be key to receive touches
    self.window = w
    self.host = host
  }

  func configure(_ configuration: MorselConfiguration) {
    self.configuration = configuration
    host?.rootView = OverlayMorselView(configuration: configuration)
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

struct MorselConfiguration {
  var shouldOpen: Binding<Bool>
  var shouldClose: Binding<Bool>
  var isChoosingDestination: Binding<Bool>
  var destinationProximity: Binding<CGFloat>
  var keyboardHeight: Binding<CGFloat>
  var isKeyboardVisible: Binding<Bool>
  var destinationPickerHeight: Binding<CGFloat>
  var isLookingUp: Binding<Bool>
  var onTap: () -> Void
  var onAdd: (String) -> Void

  static var empty: MorselConfiguration {
    .init(
      shouldOpen: .constant(false),
      shouldClose: .constant(false),
      isChoosingDestination: .constant(false),
      destinationProximity: .constant(0),
      keyboardHeight: .constant(0),
      isKeyboardVisible: .constant(false),
      destinationPickerHeight: .constant(0),
      isLookingUp: .constant(false),
      onTap: {},
      onAdd: { _ in }
    )
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
  let configuration: MorselConfiguration

  var body: some View {
    GeometryReader { geo in
      MorselView(
        shouldOpen: configuration.shouldOpen,
        shouldClose: configuration.shouldClose,
        isChoosingDestination: configuration.isChoosingDestination,
        destinationProximity: configuration.destinationProximity,
        isLookingUp: configuration.isLookingUp,
        morselColor: appSettings.morselColor,
        onTap: configuration.onTap,
        onAdd: configuration.onAdd
      )
      .scaleEffect(configuration.isChoosingDestination.wrappedValue ? 2 : 1)
      .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
      .offset(y: offsetY)
      .animation(.spring(response: 0.4, dampingFraction: 0.8), value: offsetY)
    }
    .environmentObject(appSettings)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .background(
      WindowFrameReporter { rectInWindow in
        OverlayController.shared.updateInteractiveRect(rectInWindow)
      }
      .frame(width: 1, height: 1)
      .allowsHitTesting(false),
      alignment: .bottom
    )
  }

  private var offsetY: CGFloat {
    if configuration.isChoosingDestination.wrappedValue {
      return -(configuration.destinationPickerHeight.wrappedValue / 2 + 40)
    } else if configuration.isKeyboardVisible.wrappedValue {
      return -(configuration.keyboardHeight.wrappedValue / 2)
    } else {
      return 0
    }
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
