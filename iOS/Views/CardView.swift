import SwiftUI

struct CardView: View {
  let title: String
  let value: String
  let icon: String

  var onTap: (() -> Void)?

  @EnvironmentObject var appSettings: AppSettings

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: icon)
        .font(.largeTitle)
        .foregroundStyle(tintColor)
        .padding(8)
        .background(.ultraThinMaterial, in: Circle())

      Text(value)
        .font(MorselFont.title)

      Text(title)
        .font(MorselFont.body)
        .foregroundColor(.secondary)
        .lineLimit(2, reservesSpace: true)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color(.secondarySystemBackground))
    )
    .shadow(radius: 4, y: 2)
    .onTapGesture {
      onTap?()
    }
  }

  var tintColor: Color {
    Color(appSettings.morselColor)
  }
}
