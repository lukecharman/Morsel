import SwiftUI

struct CardView: View {
  let title: String
  let value: String
  let icon: String
  let description: String?

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
        Text(value + " " + title)
          .font(MorselFont.heading)
          .lineLimit(1)

        Spacer()

        if description != nil {
          Image(systemName: "chevron.down")
            .padding(.trailing, 8)
            .tint(appSettings.morselColor)
            .onTapGesture {
              withAnimation {
                isExpanded.toggle()
              }
            }
        }
      }

      if isExpanded, let description = description {
        Text(description)
          .font(MorselFont.body)
          .foregroundColor(.secondary)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding()
    .onTapGesture {
      onTap?()
    }
    .glassEffect()
  }

  var tintColor: Color {
    Color(appSettings.morselColor)
  }
}
