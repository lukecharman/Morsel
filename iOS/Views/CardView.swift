import SwiftUI

struct CardView: View {
  let title: String
  let value: String
  let icon: String
  let description: String
  @State private var isExpanded: Bool = false

  var onTap: (() -> Void)?

  @EnvironmentObject var appSettings: AppSettings

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)
          .foregroundStyle(tintColor)
          .padding(8)
          .background(.ultraThinMaterial, in: Circle())
          .frame(width: 40, height: 40)

        (
          Text(value + " " + title)
            .font(MorselFont.heading)
        )
        .lineLimit(1)

        Spacer()

        ToggleButton(isActive: isExpanded, systemImage: "chevron.down") {
          withAnimation {
            isExpanded.toggle()
          }
        }
        .scaleEffect(0.75)
      }

      if isExpanded {
        Text(description)
          .font(MorselFont.body)
          .foregroundColor(.secondary)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
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
