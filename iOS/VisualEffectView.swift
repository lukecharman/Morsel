import SwiftUI
import UIKit

struct VisualEffectView: UIViewRepresentable {
  var effect: UIVisualEffect?
  var intensity: CGFloat = 1.0

  func makeUIView(context: Context) -> UIVisualEffectView {
    let view = UIVisualEffectView()
    view.effect = effect
    return view
  }

  func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
    uiView.effect = effect
  }
}
