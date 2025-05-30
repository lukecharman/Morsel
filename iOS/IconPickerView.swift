import SwiftUI

struct IconPickerView: View {
  @EnvironmentObject var appSettings: AppSettings

  @Environment(\.dismiss) var dismiss
  @Environment(\.colorScheme) private var colorScheme

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
          ToggleButton(
            isActive: true,
            systemImage: "xmark"
          ) {
            previewColor = nil
            dismiss()
          }
          .padding([.top, .trailing])
        }

        Spacer()

        ZStack {
          if let key = selectedKey ?? colorSwatches.first(where: { UIColor($0.color).isEquivalent(to: UIColor(appSettings.morselColor)) })?.key,
             let uiImage = UIImage(named: key) {
            Image(uiImage: uiImage)
              .resizable()
              .aspectRatio(1, contentMode: .fit)
              .frame(width: 96, height: 96)
              .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
              .shadow(radius: 8)
          }
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

        // Grid of swatches, 4 columns, 2 rows
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 24), count: 4), spacing: 20) {
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
                // Only change the app icon, do not update appSettings.morselColor
                changeIcon(to: swatch.key)
              }
            )
            .frame(width: 56, height: 48)
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .onAppear {
          if let match = colorSwatches.first(where: { UIColor($0.color).isEquivalent(to: UIColor(appSettings.morselColor)) }) {
            scrollTarget = match.key
            selectedKey = match.key
          }
        }
      }
    }
    .onAppear {
      if let match = colorSwatches.first(where: { UIColor($0.color).isEquivalent(to: UIColor(appSettings.morselColor)) }) {
        selectedKey = match.key
        previewColor = appSettings.morselColor
      }
    }
    .onChange(of: previewColor) { _, new in
      Haptics.trigger(.light)
      if let new {
        Analytics.track(ChangeIconEvent(newValue: new.description))
      }
    }
    .onDisappear {
      // Get the current morsel color key from colorSwatches (non-optional)
      let currentKey = colorSwatches.first { UIColor($0.color).isEquivalent(to: UIColor(appSettings.morselColor)) }?.key

      // Only change icon if user selected a new color key and shouldSyncIcon is on
      if let key = selectedKey,
         key != currentKey {
        changeIcon(to: key)
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
