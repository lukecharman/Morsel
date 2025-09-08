import CoreMorsel
import Foundation
import SwiftUI

struct GlassIconButton: View {
  @EnvironmentObject var appSettings: AppSettings
  let systemName: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.title2)
        .padding(12)
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .tint(Color(appSettings.morselColor))
        .foregroundStyle(appSettings.morselColor)
        .glassEffect(.regular, in: Circle())
    }
    .buttonStyle(.plain)
  }
}
