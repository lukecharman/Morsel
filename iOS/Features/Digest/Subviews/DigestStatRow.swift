import CoreMorsel
import SwiftUI

struct DigestStatRow: View {
  @EnvironmentObject var appSettings: AppSettings

  let icon: String
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .foregroundStyle(appSettings.morselColor)
        .frame(width: 24, height: 24)
        .padding(8)
        .glassEffect()
      VStack(alignment: .leading) {
        Text(label)
          .font(MorselFont.body)
          .foregroundColor(.primary.opacity(0.9))
        Text(value)
          .font(MorselFont.heading)
      }
    }
  }
}

