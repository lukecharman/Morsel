import SwiftUI

struct ColorPickerView: View {
  @EnvironmentObject var appSettings: AppSettings

  @Environment(\.dismiss) var dismiss

  @State private var blurAmount: CGFloat = 0
  @State private var pendingColor: UIColor?
  @State private var scrollTarget: String?
  @State private var selectedKey: String?

  private let colorSwatches: [(key: String, name: String, color: Color)] = [
    ("Orange", "Crispy Wotsit", .orange),
    ("Blue", "Blueberry Glaze", .blue),
    ("Red", "Ketchup Splash", .red),
    ("Green", "Mushy Pea", .green),
    ("Pink", "Fizzy Laces", .pink),
    ("White", "Marshmallow Puff", .white),
    ("Mint", "Toothpaste Gelato", .mint),
    ("Teal", "Minty Yogurt", .teal),
    ("Yellow", "Custard Spill", .yellow),
    ("Purple", "Squashed Grape", .purple),
    ("Cyan", "Bubblegum Ice", .cyan),
    ("Brown", "Burnt Toast", .brown)
  ]

  var body: some View {
    VStack {
      HStack {
        Spacer()
        ToggleButton(isActive: true, systemImage: "xmark") {
          dismiss()
        }
        .padding([.top, .trailing])
      }

      Spacer()

      ZStack {
        MorselView(
          shouldOpen: .constant(false),
          shouldClose: .constant(false),
          isChoosingDestination: .constant(true),
          destinationProximity: .constant(0.5),
          onAdd: { _ in }
        )
        .scaleEffect(2)
        .blur(radius: blurAmount)
        .animation(.easeInOut(duration: 0.6), value: blurAmount)
      }

      Spacer()

      // Display the name of the currently selected color above the swatches
      if let currentKey = scrollTarget,
         let currentName = colorSwatches.first(where: { $0.key == currentKey })?.name {
        ZStack {
          Text(currentName)
            .font(MorselFont.title)
            .id(currentKey)
            .transition(.blurReplace)
        }
        .frame(height: 32)
        .animation(.easeInOut, value: scrollTarget)
      }

      GeometryReader { proxy in
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
            Spacer()
              .frame(width: (proxy.size.width - 56) / 2)
            ForEach(colorSwatches, id: \.key) { swatch in
              ColorSwatchView(
                swatch: swatch,
                isSelected: swatch.key == scrollTarget,
                onTap: {
                  withAnimation {
                    scrollTarget = swatch.key
                  }
                  let uiColor = UIColor(swatch.color)
                  if uiColor != appSettings.morselColor {
                    pendingColor = uiColor
                    withAnimation(.easeInOut(duration: 0.3)) {
                      blurAmount = 80
                    }
                    withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                      blurAmount = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                      if let colour = pendingColor {
                        withAnimation(.easeInOut(duration: 0.3)) {
                          appSettings.morselColor = colour
                        }
                      }
                    }
                  }
                }
              )
            }
            Spacer()
              .frame(width: (proxy.size.width - 56) / 2)
          }
          .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollTarget, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .frame(height: 100)
        .onAppear {
          if let match = colorSwatches.first(where: { UIColor($0.color) == appSettings.morselColor }) {
            scrollTarget = match.key
          }
        }
        .onChange(of: scrollTarget) { _, newKey in
          if let newKey,
             let swatch = colorSwatches.first(where: { $0.key == newKey }) {
            let uiColor = UIColor(swatch.color)
            if uiColor != appSettings.morselColor {
              pendingColor = uiColor
              withAnimation(.easeInOut(duration: 0.3)) {
                blurAmount = 80
              }
              withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                blurAmount = 0
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let colour = pendingColor {
                  withAnimation(.easeInOut(duration: 0.3)) {
                    appSettings.morselColor = colour
                  }
                }
              }
            }
          }
        }
      }
      .frame(height: 100)
    }
  }
}

private struct ColorSwatchView: View {
  let swatch: (key: String, name: String, color: Color)
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    ZStack {
      UnevenRoundedRectangle(
        cornerRadii: RectangleCornerRadii(
          topLeading: 28,
          bottomLeading: 20,
          bottomTrailing: 20,
          topTrailing: 28
        ),
        style: .continuous
      )
      .fill(swatch.color)

      UnevenRoundedRectangle(
        cornerRadii: RectangleCornerRadii(
          topLeading: 28,
          bottomLeading: 20,
          bottomTrailing: 20,
          topTrailing: 28
        ),
        style: .continuous
      )
      .stroke(swatch.color.opacity(0.5), lineWidth: 2)
    }
    .frame(width: 56, height: 47)
    .padding(2)
    .onTapGesture {
      onTap()
    }
  }
}
