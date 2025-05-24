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
      PatternBackgroundView()
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
              if swatch.color != appSettings.morselColor {
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
      if let match = colorSwatches.first(where: { $0.color == appSettings.morselColor }) {
        scrollTarget = match.key
      }
    }
    .onChange(of: scrollTarget) { _, newKey in
      if let newKey,
         let swatch = colorSwatches.first(where: { $0.key == newKey }) {
        if swatch.color != appSettings.morselColor {
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

struct PatternBackgroundView: View {
  var body: some View {
    GeometryReader { geo in
      let spacing: CGFloat = 40
      let capsuleSize = CGSize(width: 12, height: 40)
      let cols = Int(geo.size.width / spacing) + 3
      let rows = Int(geo.size.height / spacing) + 3

      ZStack {
        ForEach(0..<cols, id: \.self) { column in
          ForEach(0..<rows, id: \.self) { row in
            Capsule()
              .frame(width: capsuleSize.width, height: capsuleSize.height)
              .rotationEffect(.degrees(45))
              .foregroundColor(.gray.opacity(0.05))
              .position(
                x: CGFloat(column) * spacing,
                y: CGFloat(row) * spacing
              )
          }
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .ignoresSafeArea()
  }
}
