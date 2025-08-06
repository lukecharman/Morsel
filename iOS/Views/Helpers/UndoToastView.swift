import SwiftUI

struct UndoToastView: View {
  let onUndo: () -> Void

  var body: some View {
    HStack {
      Text("Entry deleted")
      Spacer()
      Button("Undo") {
        onUndo()
      }
      .buttonStyle(.bordered)
    }
    .padding()
    .background(.ultraThinMaterial)
    .cornerRadius(12)
    .padding(.horizontal)
  }
}

#Preview {
  UndoToastView { }
}
