import CoreMorsel
import SwiftUI

struct DigestTipView: View {
  let tipText: String
  let accent: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Morsel's Tip")
        .font(MorselFont.heading)

      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text(tipText)
          .font(MorselFont.body)

        Spacer(minLength: 8)

        Button(action: {
          Haptics.trigger(.selection)
        }) {
          Image(systemName: "square.and.arrow.up")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(accent)
            .frame(width: 32, height: 32)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Share tip")
      }
    }
  }
}

