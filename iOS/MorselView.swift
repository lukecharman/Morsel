import SwiftUI

struct MorselView: View {
  @Binding var shouldOpen: Bool
  @Binding var shouldClose: Bool
  @Binding var isChoosingDestination: Bool
  @Binding var destinationProximity: CGFloat

  @EnvironmentObject var appSettings: AppSettings

  @State private var isOpen = false
  @State private var isSwallowing = false
  @State private var isBlinking = false
  @State private var isBeingTouched = false
  @State private var text: String = ""
  @State private var idleOffset: CGSize = .zero
  @State private var idleLookaroundOffset: CGFloat = .zero

  @FocusState private var isFocused: Bool

  var onTap: (() -> Void)? = nil
  var onAdd: (String) -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      face
        .rotation3DEffect(
          .degrees(isSwallowing ? -20 : -10 * sadnessLevel),
          axis: (x: 1, y: 0, z: 0),
          anchor: .center,
          perspective: 0.5
        )
        .scaleEffect(1.0 - 0.05 * sadnessLevel)
        .shadow(radius: 10 - sadnessLevel * 7)
        .rotation3DEffect(
          .degrees(isOpen ? 0 : idleLookaroundOffset),
          axis: (x: 0, y: 1, z: 0),
          anchor: .center,
          perspective: 0.5
        )
        .rotation3DEffect(
          .degrees(destinationProximity < 0 ? destinationProximity * 25 : 0),
          axis: (x: 1, y: 0, z: 0),
          anchor: .center,
          perspective: 0.5
        )
        .rotation3DEffect(
          .degrees(destinationProximity > 0 ? -destinationProximity * -25 : 0),
          axis: (x: 1, y: 0, z: 0),
          anchor: .center,
          perspective: 0.5
        )
        .scaleEffect(isBeingTouched ? CGSize(width: 0.9, height: 0.9) : CGSize(width: 1, height: 1))
        .offset(isOpen ? .zero : idleOffset)
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { _ in
              if !isBeingTouched && !isChoosingDestination {
                withAnimation {
                  isBeingTouched = true
                }
              }
            }
            .onEnded { _ in
              withAnimation {
                isBeingTouched = false
              }
              if !isChoosingDestination {
                onTap?()

                if isOpen {
                  close()
                } else {
                  open()
                }
              }
            }
        )
    }
    .padding(.bottom, 6)
    .onAppear {
      startBlinking()
      startIdleWiggle()
    }
    .onChange(of: shouldOpen) { oldValue, newValue in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        if oldValue == false && newValue == true {
          open()
        }
      }
    }
    .onChange(of: shouldClose) { oldValue, newValue in
      if oldValue == false && newValue == true {
        close()
      }
    }
  }

  var face: some View {
    let baseColor = appSettings.morselColor
    let topColor = Color(adjustedTopColor(from: baseColor, sadness: sadnessLevel, happiness: happinessLevel))


    return ZStack {
      Color.clear.frame(width: 240, height: 86)
      UnevenRoundedRectangle(
        cornerRadii: .init(
          topLeading: isOpen ? 120 : faceTopCornerRadius,
          bottomLeading: isOpen ? 32 : faceBottomCornerRadius,
          bottomTrailing: isOpen ? 32 : faceBottomCornerRadius,
          topTrailing: isOpen ? 120 : faceTopCornerRadius
        ),
        style: .continuous
      )
      .stroke(topColor.opacity(0.5), lineWidth: 2)
      .fill(
        LinearGradient(
          colors: [
            topColor,
            Color(baseColor),
            Color(baseColor),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .frame(
        width: isOpen ? 240 : .lerp(from: 86, to: 107, by: happinessLevel),
        height: isOpen ? 120 : .lerp(from: 64, to: 80, by: happinessLevel)
      )
      .animation(.easeInOut(duration: 0.3), value: faceBottomCornerRadius)
      .overlay(
        facialFeatures
      )
    }
  }

  var facialFeatures: some View {
    VStack {
      eyes
      mouth
      Spacer()
    }
    .rotation3DEffect(
      .degrees(isSwallowing ? -8 : 0),
      axis: (x: 1, y: 0, z: 0),
      anchor: .center,
      perspective: 0.5
    )
    .rotation3DEffect(
      .degrees(isOpen ? 0 : idleLookaroundOffset),
      axis: (x: 0, y: 1, z: 0),
      anchor: .center,
      perspective: 0.5
    )
  }

  var eyes: some View {
    let eyeSize: CGFloat = .lerp(from: 10, to: 8, by: sadnessLevel)
    let eyeOffset: CGFloat = .lerp(from: 16, to: 18, by: sadnessLevel)

    return HStack(spacing: isOpen ? 24 : .lerp(from: 12, to: 15, by: happinessLevel)) {
      EyebrowedEyeShape(
        eyebrowAmount: destinationProximity > 0 ? happinessLevel / 4 : sadnessLevel / 2,
        angle: destinationProximity > 0 ? .degrees(30) : .degrees(160)
      )
        .fill(Color(mouthColor(from: AppSettings.shared.morselColor)))
        .frame(width: eyeSize, height: eyeSize)
        .scaleEffect(x: eyeScaleX, y: eyeScaleY)
        .shadow(radius: 4)
      EyebrowedEyeShape(
        eyebrowAmount: destinationProximity > 0 ? happinessLevel / 4 : sadnessLevel / 2,
        angle: destinationProximity > 0 ? .degrees(330) : .degrees(200)
      )
        .fill(Color(mouthColor(from: AppSettings.shared.morselColor)))
        .frame(width: eyeSize, height: eyeSize)
        .scaleEffect(x: eyeScaleX, y: eyeScaleY)
        .shadow(radius: 4)
    }
    .offset(y: eyeOffset)
  }

  var mouth: some View {
    ZStack {
      UnevenRoundedRectangle(
        cornerRadii: .init(
          topLeading: mouthTopCornerRadius,
          bottomLeading: mouthBottomCornerRadius,
          bottomTrailing: mouthBottomCornerRadius,
          topTrailing: mouthTopCornerRadius
        ),
        style: .continuous
      )
      .fill(Color(mouthColor(from: AppSettings.shared.morselColor)))
      .animation(.easeInOut(duration: 0.2), value: sadnessLevel)
      .frame(
        width: isOpen ? 170 : .lerp(from: 24, to: 76, by: happinessLevel),
        height: isOpen ? 74 : .lerp(from: 8, to: 30, by: happinessLevel)
      )
      .scaleEffect(1 - sadnessLevel * 0.3, anchor: .center)
      .offset(y: isOpen ? 16 + droopOffset : 24 + droopOffset)
      .shadow(radius: 10)
      textField
    }
  }

  var sadnessLevel: CGFloat {
    min(max(-destinationProximity, 0), 1)
  }

  var happinessLevel: CGFloat {
    max(destinationProximity, 0)
  }

  var droopOffset: CGFloat {
    destinationProximity < 0 ? -destinationProximity * 4 : 0
  }

  var textField: some View {
    TextField("", text: $text)
      .focused($isFocused)
      .submitLabel(.done)
      .onSubmit {
        isFocused = false
        if text.count > 0 {
          onAdd(text)
        }
        close()
      }
      .font(MorselFont.body)
      .tint(.blue)
      .foregroundStyle(.white)
      .allowsHitTesting(isOpen)
      .opacity(isOpen ? 1 : 0)
      .frame(width: 160, height: isOpen ? 72 : 0)
      .multilineTextAlignment(.center)
      .backgroundStyle(Color.black.opacity(0.5))
      .textFieldStyle(.plain)
      .scaleEffect(isOpen ? CGSize(width: 1, height: 1) : .zero)
      .offset(y: isOpen ? 14 : 32)
  }

  var eyeScaleX: CGFloat {
    if destinationProximity < 0 {
      return max(0.4, 1 + destinationProximity * 0.04)
    } else if destinationProximity > 0 {
      return 1 + destinationProximity * 0.2
    } else {
      return 1
    }
  }

  var eyeScaleY: CGFloat {
    if isSwallowing || isBlinking {
      return 0.25
    } else if destinationProximity < 0 {
      return max(0.4, 1 + destinationProximity * 0.04)
    } else if destinationProximity > 0 {
      return 1 + destinationProximity * 0.2
    } else {
      return 1
    }
  }

  var faceTopCornerRadius: CGFloat {
    if isOpen {
      return 120
    } else if destinationProximity > 0 {
      return .lerp(from: 32, to: 120, by: happinessLevel)
    } else {
      return 32 + (-destinationProximity * 16)
    }
  }

  var faceBottomCornerRadius: CGFloat {
    if isOpen {
      return 32
    } else if destinationProximity > 0 {
      return .lerp(from: 32, to: 32, by: happinessLevel) // stays flat
    } else {
      return 32 + destinationProximity * 12
    }
  }

  var mouthTopCornerRadius: CGFloat {
    isOpen ? 16 : .lerp(from: 4, to: 6, by: happinessLevel)
  }

  var mouthBottomCornerRadius: CGFloat {
    isOpen ? 48 : .lerp(from: 4, to: 48, by: happinessLevel)
  }

  func open() {
    withAnimation {
      isOpen = true
      shouldOpen = false
      isFocused = true
    }
  }

  func close() {
    withAnimation {
      text = ""
      isOpen = false
      shouldClose = false
      isFocused = false
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      withAnimation {
        isSwallowing = true
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7
    ) {
      withAnimation {
        isSwallowing = false
      }
    }
  }

  func startBlinking() {
    Timer.scheduledTimer(withTimeInterval: Double.random(in: 4...8), repeats: true) { _ in
      withAnimation {
        isBlinking = true
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        withAnimation {
          isBlinking = false
        }
      }
    }
  }

  func startIdleWiggle() {
    Timer.scheduledTimer(withTimeInterval: Double.random(in: 4...7), repeats: true) { _ in
      let offsetY = CGFloat(Int.random(in: -1...8))
      withAnimation(.easeInOut(duration: 1)) {
        idleOffset = CGSize(width: 0, height: offsetY)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation(.easeInOut(duration: 0.3)) {
          idleOffset = .zero
        }
      }
    }
    Timer.scheduledTimer(withTimeInterval: Double.random(in: 5...10), repeats: true) { _ in
      let direction: CGFloat = Bool.random() ? 1 : -1
      withAnimation(.easeInOut(duration: 0.1)) {
        idleLookaroundOffset = 10 * direction
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.easeInOut(duration: 0.2)) {
          idleLookaroundOffset = -6 * direction
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          withAnimation(.easeInOut(duration: 0.3)) {
            idleLookaroundOffset = 0
          }
        }
      }
    }
  }

  func adjustedTopColor(from color: UIColor, sadness: CGFloat, happiness: CGFloat) -> UIColor {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return color }

    let adjustedSaturation = max(min(saturation * (1 - sadness * 0.4), 1), 0)
    let adjustedBrightness = max(min(brightness * (1 - happiness * 0.18), 1), 0)

    return UIColor(hue: hue, saturation: adjustedSaturation, brightness: adjustedBrightness, alpha: alpha)
  }

  func mouthColor(from color: UIColor, percentage: CGFloat = 0.75) -> UIColor {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
      return color
    }

    let adjustedBrightness = max(brightness * (1 - percentage), 0)
    return UIColor(hue: hue, saturation: saturation, brightness: adjustedBrightness, alpha: alpha)
  }
}

#Preview {
  MorselView(
    shouldOpen: .constant(false),
    shouldClose: .constant(false),
    isChoosingDestination: .constant(false),
    destinationProximity: .constant(0)
  ) { _ in }
#if os(iOS)
    .background(Color(.systemBackground))
#endif
}

extension CGFloat {
  static func lerp(from: CGFloat, to: CGFloat, by amount: CGFloat) -> CGFloat {
    return from + (to - from) * amount
  }
}

struct AnimatedEyeView: View {
  @Binding var amount: CGFloat
  @Binding var angle: Angle

  var body: some View {
    EyebrowedEyeShape(eyebrowAmount: amount, angle: angle)
      .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
      .animation(.easeInOut(duration: 0.3), value: amount)
  }
}

struct EyebrowedEyeShape: Shape {
  var eyebrowAmount: CGFloat // 0 = circle, 1 = flat segment
  var angle: Angle           // angle of flat segment

  var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get { AnimatablePair(eyebrowAmount, CGFloat(angle.degrees)) }
    set {
      eyebrowAmount = newValue.first
      angle = .degrees(Double(newValue.second))
    }
  }

  func path(in rect: CGRect) -> Path {
    let clamped = min(max(eyebrowAmount, 0), 1)
    let radius = min(rect.width, rect.height) / 2
    let center = CGPoint(x: rect.midX, y: rect.midY)

    var path = Path()

    if clamped == 0 {
      path.addEllipse(in: CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
      ))
      return path
    }

    let delta = 90.0 * (1 - clamped)
    let startAngle = angle + .degrees(delta)
    let endAngle = angle + .degrees(180 - delta)

    path.addArc(
      center: center,
      radius: radius,
      startAngle: startAngle,
      endAngle: endAngle,
      clockwise: true
    )

    // Flat line to close the arc
    let left = CGPoint(
      x: center.x + radius * cos(CGFloat(endAngle.radians)),
      y: center.y + radius * sin(CGFloat(endAngle.radians))
    )
    let right = CGPoint(
      x: center.x + radius * cos(CGFloat(startAngle.radians)),
      y: center.y + radius * sin(CGFloat(startAngle.radians))
    )
    path.addLine(to: right)
    path.addLine(to: left)

    path.closeSubpath()
    return path
  }
}
