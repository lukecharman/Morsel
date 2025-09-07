import CoreMorsel
import SwiftUI

struct DigestHeaderView: View {
  let title: String
  let dateRange: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .padding(.top, 16)
        .font(MorselFont.title)

      Text(dateRange)
        .font(MorselFont.body)
        .foregroundStyle(.secondary)
    }
  }
}

