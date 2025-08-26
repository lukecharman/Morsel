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
  var isKeyboardVisible: Binding<Bool>
  var isLookingUp: Binding<Bool>
  var onTap: () -> Void
  var onAdd: (String, Bool) -> Void

  static var empty: MorselConfiguration {
    .init(
      shouldOpen: .constant(false),
      shouldClose: .constant(false),
      isChoosingDestination: .constant(false),
      isKeyboardVisible: .constant(false),
      isLookingUp: .constant(false),
      onTap: {},
      onAdd: { _, _ in }
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
      guard let window = view.window, let superview = view.superview else {
        onChange(nil)
        return
      }
      // Account for transforms like scale or offset by using the view's frame.
      let frameInWindow = superview.convert(view.frame, to: window)
      onChange(frameInWindow)
    }
  }
}

private struct OverlayMorselView: View {
  @ObservedObject private var appSettings = AppSettings.shared
  let configuration: MorselConfiguration
  @State private var isPickingDestination = false
  @State private var pendingText = ""
  @State private var destinationProximity: CGFloat = 0
  @State private var destinationPickerHeight: CGFloat = 0
  @State private var keyboardHeight: CGFloat = 0

  var body: some View {
    GeometryReader { _ in
      ZStack {
        MorselView(
          shouldOpen: configuration.shouldOpen,
          shouldClose: configuration.shouldClose,
          isChoosingDestination: $isPickingDestination,
          destinationProximity: $destinationProximity,
          isLookingUp: configuration.isLookingUp,
          morselColor: appSettings.morselColor,
          onTap: configuration.onTap,
          onAdd: { text in
            pendingText = text
            withAnimation { isPickingDestination = true }
          }
        )
        .fixedSize()
        .scaleEffect(isPickingDestination ? 2 : 1)
        .background(
          WindowFrameReporter { rectInWindow in
            if !isPickingDestination {
              OverlayController.shared.updateInteractiveRect(rectInWindow)
            }
          }
          .allowsHitTesting(false)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .offset(y: offsetY)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: offsetY)

        if isPickingDestination {
          DestinationPickerView(
            onPick: { isForMorsel in
              configuration.onAdd(pendingText, isForMorsel)
              pendingText = ""
              withAnimation { isPickingDestination = false }
            },
            onCancel: {
              pendingText = ""
              withAnimation { isPickingDestination = false }
            },
            onDrag: { position in
              withAnimation { destinationProximity = position }
            }
          )
          .frame(maxHeight: .infinity)
          .ignoresSafeArea()
          .background(
            HeightReader { height in
              destinationPickerHeight = height
            }
          )
        }
      }
    }
    .environmentObject(appSettings)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .onReceive(NotificationPublishers.keyboardWillShow) { notification in
      if let height = extractKeyboardHeight(from: notification) {
        withAnimation {
          keyboardHeight = height
          configuration.isKeyboardVisible.wrappedValue = true
        }
      }
    }
    .onReceive(NotificationPublishers.keyboardWillHide) { _ in
      withAnimation {
        keyboardHeight = 0
        configuration.isKeyboardVisible.wrappedValue = false
      }
    }
    .onChange(of: isPickingDestination) { _, newValue in
      configuration.isChoosingDestination.wrappedValue = newValue
      if newValue {
        OverlayController.shared.updateInteractiveRect(UIScreen.main.bounds)
      } else {
        OverlayController.shared.updateInteractiveRect(nil)
      }
    }
  }

  private var offsetY: CGFloat {
    if isPickingDestination {
      return -(destinationPickerHeight / 2 + 40)
    } else if configuration.isKeyboardVisible.wrappedValue {
      return -(keyboardHeight / 2)
    } else {
      return 0
    }
  }

  private func extractKeyboardHeight(from notification: Notification) -> CGFloat? {
    guard
      let userInfo = notification.userInfo,
      let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
    else {
      return nil
    }
    return frame.height
  }
}
final class SelectiveHitWindow: UIWindow {
  /// Window-space hit area. If empty, everything passes through.
  var interactivePath: UIBezierPath = .init()

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    interactivePath.contains(point)
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard point(inside: point, with: event) else { return nil }
    return super.hitTest(point, with: event)
  }

  // Optional: allow hardware keyboard to stay with underlying window.
  override var canBecomeKey: Bool { true }
}
