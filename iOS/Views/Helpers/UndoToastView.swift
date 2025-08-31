import CoreMorsel
import SwiftUI

struct UndoToastView: View {
  let onUndo: () -> Void

  var body: some View {
    HStack {
      Text("Entry deleted")
        .font(MorselFont.body)
      Spacer()
      Button("Undo") {
        onUndo()
      }
      .font(MorselFont.body)
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
