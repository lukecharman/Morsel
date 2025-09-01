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
      // Header row (no longer a Button; we handle taps on the container)
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

        if description == nil {
          Image(systemName: "chevron.right")
            .padding(.trailing, 8)
            .tint(appSettings.morselColor)
        }
      }
      // Ensure the entire horizontal header area is tappable
      .contentShape(Rectangle())

      if let description = description, isExpanded {
        // Only insert this view when expanded, so collapsed height is correct.
        VStack(alignment: .leading, spacing: 0) {
          Text(description)
            .font(MorselFont.body)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .transition(
              .asymmetric(
                insertion: .opacity
                  .combined(with: .move(edge: .top))
                  .combined(with: .scale(scale: 1.0, anchor: .top)),
                removal: .opacity
                  .combined(with: .move(edge: .top))
                  .combined(with: .scale(scale: 0.001, anchor: .top))
              )
            )
        }
        .animation(.easeInOut, value: isExpanded)
      }
    }
    .padding()
    .glass(.regular, in: shape)
    // Make the entire card tappable, including description and padding
    .contentShape(Rectangle())
    .highPriorityGesture(
      TapGesture()
        .onEnded {
          onTap?()
          if description != nil {
            withAnimation(.easeInOut) {
              isExpanded.toggle()
            }
          }
        }
    )
    // Accessibility: announce as a button for full-card tap behavior
    .accessibilityAddTraits(.isButton)
  }

  var shape: some Shape {
    if isFirst && isLast { UnevenRoundedRectangle(cornerRadii: singleRect) }
    else if isFirst { UnevenRoundedRectangle(cornerRadii: topRect) }
    else if isLast { UnevenRoundedRectangle(cornerRadii: bottomRect) }
    else { UnevenRoundedRectangle(cornerRadii: midRect) }
  }

  var singleRect: RectangleCornerRadii =
  RectangleCornerRadii(topLeading: 16, bottomLeading: 16, bottomTrailing: 16, topTrailing: 16)

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
