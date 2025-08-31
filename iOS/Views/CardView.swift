import CoreMorsel
import SwiftUI

struct CardView: View {
  let title: String
  let value: String
  let icon: String

  var description: String? = nil
  var isFirst: Bool = false
  var isLast: Bool = false

  @State private var isExpanded: Bool = false

  var onTap: (() -> Void)?

  @EnvironmentObject var appSettings: AppSettings

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button {
        onTap?()
        if description != nil {
          withAnimation {
            isExpanded.toggle()
          }
        }
      } label: {
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
              .rotationEffect(.degrees(isExpanded ? 180 : 0))
              .animation(.easeInOut(duration: 0.2), value: isExpanded)
              .padding(.trailing, 8)
              .tint(appSettings.morselColor)
          }
        }
        // Ensure the entire horizontal area is tappable, not just subviews
        .contentShape(Rectangle())
      }
      // Keep the row visually plain (no default button styling)
      .buttonStyle(.plain)

      if isExpanded, let description = description {
        Text(description)
          .font(MorselFont.body)
          .foregroundColor(.secondary)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding()
    .glass(.regular, in: shape)
  }

  var shape: some Shape {
    if isFirst { UnevenRoundedRectangle(cornerRadii: topRect) }
    else if isLast { UnevenRoundedRectangle(cornerRadii: bottomRect) }
    else { UnevenRoundedRectangle(cornerRadii: midRect) }
  }

  var topRect: RectangleCornerRadii =
    RectangleCornerRadii(topLeading: 16, bottomLeading: 0, bottomTrailing: 0, topTrailing: 16)

  var bottomRect: RectangleCornerRadii =
    RectangleCornerRadii(topLeading: 0, bottomLeading: 16, bottomTrailing: 16, topTrailing: 0)

  var midRect: RectangleCornerRadii =
    RectangleCornerRadii(topLeading: 0, bottomLeading: 0, bottomTrailing: 0, topTrailing: 0)

  var tintColor: Color {
    Color(appSettings.morselColor)
  }
}
