import Foundation
import SwiftUI
import UIKit

struct ControllableTextField: UIViewRepresentable {
  @Binding var text: String
  @Binding var isFocused: Bool
  var onValidSubmit: () -> Void
  var onInvalidSubmit: () -> Void

  class Coordinator: NSObject, UITextFieldDelegate {
    var parent: ControllableTextField

    init(_ parent: ControllableTextField) {
      self.parent = parent
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      if parent.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        parent.onInvalidSubmit()
        return false
      }
      parent.onValidSubmit()
      return true
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
      parent.text = textField.text ?? ""
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeUIView(context: Context) -> UITextField {
    let tf = UITextField()
    tf.delegate = context.coordinator
    tf.textAlignment = .center
    tf.font = UIFont(name: "Quicksand-Semibold", size: 16)
    tf.returnKeyType = .done
    tf.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChangeSelection(_:)), for: .editingChanged)
    return tf
  }

  func updateUIView(_ uiView: UITextField, context: Context) {
    uiView.text = text
    if isFocused && !uiView.isFirstResponder {
      uiView.becomeFirstResponder()
    } else if !isFocused && uiView.isFirstResponder {
      uiView.resignFirstResponder()
    }
  }
}
