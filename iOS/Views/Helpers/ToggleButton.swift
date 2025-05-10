import SwiftUI

struct ToggleButton: View {
  let isActive: Bool
  let systemImage: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: isActive ? "xmark" : systemImage)
        .font(.title2)
        .padding(12)
        .frame(width: 44, height: 44)
        .background(.thinMaterial)
        .clipShape(Circle())
    }
    .animation(.easeInOut(duration: 0.25), value: isActive)
  }
}
