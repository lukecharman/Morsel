import SwiftUI

struct ColorPickerView: View {
  @EnvironmentObject var appSettings: AppSettings

  @Environment(\.dismiss) var dismiss

  @State private var pendingColor: UIColor?
  @State private var scrollTarget: String?
  @State private var selectedKey: String?
  @State private var previewColor: Color?
  @State private var shouldSyncIcon: Bool = true

  @GestureState private var dragTranslation: CGFloat = 0
  @State private var scrollOffset: CGFloat = 0

  private let colorSwatches: [(key: String, name: String, color: Color)] = [
    ("Orange", "Crispy Wotsit", .orange),
    ("Blue", "Blueberry Glaze", .blue),
    ("Red", "Ketchup Splash", .red),
    ("Green", "Mushy Pea", .green),
    ("Pink", "Fizzy Laces", .pink),
    ("Mint", "Toothpaste Gelato", .mint),
    ("Yellow", "Custard Spill", .yellow),
    ("Purple", "Squashed Grape", .purple)
  ]

  var body: some View {
    ZStack {
      BackgroundGradientView()
      VStack {
        HStack {
          Spacer()
          ToggleButton(isActive: true, systemImage: "xmark") {
            previewColor = nil
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
            morselColor: previewColor ?? appSettings.morselColor,
            onAdd: { _ in },
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

        VStack {
          Toggle(isOn: $shouldSyncIcon) {
            Text("Sync app icon?")
              .font(MorselFont.body)
              .foregroundStyle(.primary)
          }
          .onSubmit {
            if shouldSyncIcon {
              Haptics.trigger(.selection)
            } else {
              Haptics.trigger(.light)
            }
          }
          .tint(previewColor)
          .padding(.horizontal)
          .padding(.bottom, 24)
        }

        Button(action: {
          if let key = selectedKey,
             let swatch = colorSwatches.first(where: { $0.key == key }) {
            withAnimation(.easeInOut(duration: 0.3)) {
              appSettings.morselColor = swatch.color
              previewColor = nil
            }
            if shouldSyncIcon {
              changeIcon(to: swatch.key)
            }
            dismiss()
          }
        }) {
          Text("Save")
            .font(MorselFont.title)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding()
            .background(previewColor ?? appSettings.morselColor)
            .clipShape(Capsule(style: .continuous))
            .padding(.horizontal)
        }
        .padding(.bottom, 24)
      }
    }
    .onAppear {
      if let match = colorSwatches.first(where: { UIColor($0.color).isEquivalent(to: UIColor(appSettings.morselColor)) }) {
        selectedKey = match.key
        previewColor = appSettings.morselColor
      }
    }
    .onChange(of: previewColor) { _ in
      Haptics.trigger(.light)
    }
  }

  var scrollView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        Spacer()
          .frame(width: UIScreen.main.bounds.width / 2 - 56 / 2 - 16)
        ForEach(colorSwatches, id: \.key) { swatch in
          ColorSwatchView(
            swatch: swatch,
            isSelected: swatch.key == scrollTarget,
            onTap: {
              withAnimation {
                scrollTarget = swatch.key
              }
              selectedKey = swatch.key
              previewColor = swatch.color
            }
          )
        }
        Spacer()
          .frame(width: UIScreen.main.bounds.width / 2 - 56 / 2 - 16)
      }
      .offset(x: scrollOffset + dragTranslation)
      .gesture(
        DragGesture()
          .updating($dragTranslation) { value, state, _ in
            state = value.translation.width
          }
          .onEnded { value in
            let swatchWidth: CGFloat = 56 + 16
            let velocity = value.velocity.width
            let offsetWithTranslation = scrollOffset + value.translation.width
            let predictedOffset = offsetWithTranslation + velocity * 0.2 // a light projection
            let estimatedIndex = -predictedOffset / swatchWidth
            let clampedIndex = min(max(Int(round(estimatedIndex)), 0), colorSwatches.count - 1)
            let newOffset = -CGFloat(clampedIndex) * swatchWidth

            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.85, blendDuration: 0.25)) {
              scrollOffset = newOffset
            }

            let swatch = colorSwatches[clampedIndex]
            scrollTarget = swatch.key
            selectedKey = swatch.key
            previewColor = swatch.color
          }
      )
    }
    .defaultScrollAnchor(.center)
    .scrollPosition(id: $scrollTarget, anchor: .center)
    .frame(height: 100)
    .onAppear {
      if let match = colorSwatches.first(where: { UIColor($0.color).isEquivalent(to: UIColor(appSettings.morselColor)) }) {
        scrollTarget = match.key
      }
    }
  }
private func changeIcon(to key: String) {
    guard UIApplication.shared.supportsAlternateIcons else {
      print("Alternate icons not supported.")
      return
    }

    UIApplication.shared.setAlternateIconName(key) { error in
      if let error = error {
        print("Failed to change icon: \(error.localizedDescription)")
      } else {
        print("App icon successfully changed to \(key)")
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
          topLeading: 24,
          bottomLeading: 20,
          bottomTrailing: 20,
          topTrailing: 24
        ),
        style: .continuous
      )
      .fill(swatch.color)
    }
    .frame(width: 56, height: 48)
    .padding(.vertical, 2)
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
