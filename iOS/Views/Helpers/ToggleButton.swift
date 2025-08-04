import CoreMorsel
import SwiftUI

struct ToggleButton: View {
  let isActive: Bool
  let systemImage: String
  let action: () -> Void

  @EnvironmentObject var appSettings: AppSettings

  var body: some View {
    Button(action: action) {
      Image(systemName: isActive ? "xmark" : systemImage)
        .font(.title2)
        .padding(12)
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .tint(.white)
        .glass(.regular)
    }
    .animation(.easeInOut(duration: 0.25), value: isActive)
  }

  var tintColor: Color {
    Color(appSettings.morselColor)
  }
}
