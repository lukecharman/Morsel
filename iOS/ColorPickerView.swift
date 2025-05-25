import SwiftUI

struct ColorPickerView: View {
  @EnvironmentObject var appSettings: AppSettings

  @Environment(\.dismiss) var dismiss

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
    ZStack {
      BackgroundGradientView()
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
            isLookingUp: .constant(false),
            onAdd: { _ in }
          )
          .scaleEffect(2)
        }

        Spacer()

        // Display the name of the currently selected color above the swatches
        if let currentKey = scrollTarget,
           let currentName = colorSwatches.first(where: { $0.key == currentKey })?.name {
          ZStack {
            Text(currentName)
              .font(MorselFont.title)
              .id(currentKey)
              .transition(.blurReplace.combined(with: .opacity))
          }
          .frame(height: 32)
          .animation(.easeInOut, value: scrollTarget)
        }

        scrollView
      }
    }
    .onAppear {
      if let match = colorSwatches.first(where: { UIColor($0.color).isEquivalent(to: UIColor(appSettings.morselColor)) }) {
        selectedKey = match.key
      }
    }
  }

  var scrollView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        Spacer()
          .frame(width: (UIScreen.main.bounds.width - 56) / 2)
        ForEach(colorSwatches, id: \.key) { swatch in
          ColorSwatchView(
            swatch: swatch,
            isSelected: swatch.key == scrollTarget,
            onTap: {
              withAnimation {
                scrollTarget = swatch.key
              }
              if !UIColor(swatch.color).isEquivalent(to: UIColor(appSettings.morselColor)) {
                pendingColor = UIColor(swatch.color)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                  if let colour = pendingColor {
                    withAnimation(.easeInOut(duration: 0.3)) {
                      appSettings.morselColor = Color(colour)
                    }
                  }
                }
              }
            }
          )
        }
        Spacer()
          .frame(width: (UIScreen.main.bounds.width - 56) / 2)
      }
      .scrollTargetLayout()
    }
    .defaultScrollAnchor(.center)
    .scrollPosition(id: $scrollTarget, anchor: .center)
    .scrollTargetBehavior(.viewAligned)
    .frame(height: 100)
    .onAppear {
      if let match = colorSwatches.first(where: { UIColor($0.color).isEquivalent(to: UIColor(appSettings.morselColor)) }) {
        scrollTarget = match.key
      }
    }
    .onChange(of: scrollTarget) { _, newKey in
      if let newKey, let swatch = colorSwatches.first(where: { $0.key == newKey }) {
        if !UIColor(swatch.color).isEquivalent(to: UIColor(appSettings.morselColor)) {
          pendingColor = UIColor(swatch.color)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let colour = pendingColor {
              withAnimation(.easeInOut(duration: 0.3)) {
                appSettings.morselColor = Color(colour)
              }
            }
          }
        }
      }
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
    }
    .frame(width: 56, height: 47)
    .padding(2)
    .onTapGesture {
      onTap()
    }
  }
}

private extension UIColor {
  func isEquivalent(to other: UIColor, tolerance: CGFloat = 0.01) -> Bool {
    var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
    var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

    guard self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
          other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
      return false
    }

    return abs(r1 - r2) < tolerance &&
           abs(g1 - g2) < tolerance &&
           abs(b1 - b2) < tolerance &&
           abs(a1 - a2) < tolerance
  }
}
