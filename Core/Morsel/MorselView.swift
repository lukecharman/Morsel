import SwiftUI

enum MorselDebugControlMode {
  case automatic
  case manual
}

struct MorselDebugBindings {
  var isBlinking: Binding<Bool>?
  var isSwallowing: Binding<Bool>?
  var idleOffset: Binding<CGSize>?
  var idleLookaroundOffset: Binding<CGFloat>?
}

struct MorselView: View {
  @Binding var shouldOpen: Bool
  @Binding var shouldClose: Bool
  @Binding var isChoosingDestination: Bool
  @Binding var destinationProximity: CGFloat
  @Binding var isLookingUp: Bool

  @EnvironmentObject var appSettings: AppSettings

  @State private var isOpen = false
  @State private var isSwallowingInternal = false
  @State private var isBlinkingInternal = false
  @State private var idleOffsetInternal: CGSize = .zero
  @State private var idleLookaroundOffsetInternal: CGFloat = .zero
  @State private var isBeingTouched = false
  @State private var text: String = ""

  @FocusState private var isFocused: Bool

  var morselColor: Color
  var supportsOpen: Bool = true

  var onTap: (() -> Void)? = nil
  var onAdd: (String) -> Void

  var debugBindings: MorselDebugBindings? = nil

  var debugControlMode: MorselDebugControlMode = .automatic

  private var isSwallowing: Bool {
    switch debugControlMode {
    case .manual:
      return debugBindings?.isSwallowing?.wrappedValue ?? isSwallowingInternal
    case .automatic:
      return isSwallowingInternal
    }
  }

  private var isBlinking: Bool {
    switch debugControlMode {
    case .manual:
      return debugBindings?.isBlinking?.wrappedValue ?? isBlinkingInternal
    case .automatic:
      return isBlinkingInternal
    }
  }

  private var idleOffset: CGSize {
    switch debugControlMode {
    case .manual:
      return debugBindings?.idleOffset?.wrappedValue ?? idleOffsetInternal
    case .automatic:
      return idleOffsetInternal
    }
  }

  private var idleLookaroundOffset: CGFloat {
    switch debugControlMode {
    case .manual:
      return debugBindings?.idleLookaroundOffset?.wrappedValue ?? idleLookaroundOffsetInternal
    case .automatic:
      return idleLookaroundOffsetInternal
    }
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      SpeechBubble(isOpen: $isOpen, isBeingTouched: $isBeingTouched)
        .offset(y: -80)
        .zIndex(1)
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
          .degrees(destinationProximity > 0 ? -destinationProximity * -25 : (isLookingUp ? -20 : 0)),
          axis: (x: 1, y: 0, z: 0),
          anchor: .center,
          perspective: 0.5
        )
        .scaleEffect(isBeingTouched ? CGSize(width: 0.9, height: 0.9) : CGSize(width: 1, height: 1))
        .offset(isOpen ? .zero : idleOffset)
        .gesture(
          supportsOpen ?
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
          : nil
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
    let baseColor = morselColor
    let topColor = Color(adjustedTopColor(from: UIColor(baseColor), sadness: sadnessLevel, happiness: happinessLevel))

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
        .fill(Color.darkened(from: morselColor))
        .frame(width: eyeSize, height: eyeSize)
        .scaleEffect(x: eyeScaleX, y: eyeScaleY)
        .shadow(radius: 4)
      EyebrowedEyeShape(
        eyebrowAmount: destinationProximity > 0 ? happinessLevel / 4 : sadnessLevel / 2,
        angle: destinationProximity > 0 ? .degrees(330) : .degrees(200)
      )
        .fill(Color.darkened(from: morselColor))
        .frame(width: eyeSize, height: eyeSize)
        .scaleEffect(x: eyeScaleX, y: eyeScaleY)
        .shadow(radius: 4)
    }
    .offset(y: isLookingUp ? eyeOffset - 4 : eyeOffset)
    .scaleEffect(x: 1, y: isLookingUp ? 0.85 : 1)
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
      .fill(Color.darkened(from: morselColor))
      .animation(.easeInOut(duration: 0.2), value: sadnessLevel)
      .frame(
        width: isOpen ? 170 : .lerp(from: 24, to: 76, by: happinessLevel),
        height: isOpen ? 74 : .lerp(from: 8, to: 30, by: happinessLevel)
      )
      .scaleEffect(1 - sadnessLevel * 0.3, anchor: .center)
      .offset(y: (isOpen ? 16 : 24) + droopOffset - (isLookingUp ? 4 : 0))
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
        if debugControlMode == .manual, let ext = debugBindings?.isSwallowing {
          ext.wrappedValue = true
        } else {
          isSwallowingInternal = true
        }
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7
    ) {
      withAnimation {
        if debugControlMode == .manual, let ext = debugBindings?.isSwallowing {
          ext.wrappedValue = false
        } else {
          isSwallowingInternal = false
        }
      }
    }
  }

  func startBlinking() {
    Timer.scheduledTimer(withTimeInterval: Double.random(in: 4...8), repeats: true) { _ in
      withAnimation {
        if debugControlMode == .manual, let ext = debugBindings?.isBlinking {
          ext.wrappedValue = true
        } else {
          isBlinkingInternal = true
        }
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        withAnimation {
          if debugControlMode == .manual, let ext = debugBindings?.isBlinking {
            ext.wrappedValue = false
          } else {
            isBlinkingInternal = false
          }
        }
      }
    }
  }

  func startIdleWiggle() {
    Timer.scheduledTimer(withTimeInterval: Double.random(in: 4...7), repeats: true) { _ in
      let offsetY = CGFloat(Int.random(in: -1...8))
      withAnimation(.easeInOut(duration: 1)) {
        if debugControlMode == .manual, let ext = debugBindings?.idleOffset {
          ext.wrappedValue = CGSize(width: 0, height: offsetY)
        } else {
          idleOffsetInternal = CGSize(width: 0, height: offsetY)
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation(.easeInOut(duration: 0.3)) {
          if debugControlMode == .manual, let ext = debugBindings?.idleOffset {
            ext.wrappedValue = .zero
          } else {
            idleOffsetInternal = .zero
          }
        }
      }
    }
    Timer.scheduledTimer(withTimeInterval: Double.random(in: 5...10), repeats: true) { _ in
      let direction: CGFloat = Bool.random() ? 1 : -1
      withAnimation(.easeInOut(duration: 0.1)) {
        if debugControlMode == .manual, let ext = debugBindings?.idleLookaroundOffset {
          ext.wrappedValue = 10 * direction
        } else {
          idleLookaroundOffsetInternal = 10 * direction
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.easeInOut(duration: 0.2)) {
          if debugControlMode == .manual, let ext = debugBindings?.idleLookaroundOffset {
            ext.wrappedValue = -6 * direction
          } else {
            idleLookaroundOffsetInternal = -6 * direction
          }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          withAnimation(.easeInOut(duration: 0.3)) {
            if debugControlMode == .manual, let ext = debugBindings?.idleLookaroundOffset {
              ext.wrappedValue = 0
            } else {
              idleLookaroundOffsetInternal = 0
            }
          }
        }
      }
    }
  }

  func adjustedTopColor(
    from color: UIColor,
    sadness: CGFloat,
    happiness: CGFloat
  ) -> UIColor {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    guard color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else { return color }

    let adjustedSaturation = max(min(saturation * (1 - sadness * 0.4), 1), 0)
    let adjustedBrightness = max(min(brightness * (1 - happiness * 0.18), 1), 0)

    return UIColor(hue: hue, saturation: adjustedSaturation, brightness: adjustedBrightness, alpha: alpha)
  }
  
}

struct SpeechBubble: View {
  @Binding var isOpen: Bool
  @Binding var isBeingTouched: Bool

  @Namespace var union

  @State private var currentText = ""
  @State private var showSmallBubble = false
  @State private var showMediumBubble = false
  @State private var showMainBubble = false

  private let phrases = [
    "Hey there! 👋",
    "Feeling snacky?",
    "What's cooking?",
    "Ready to log?",
    "Tap me! 😊",
    "I'm here to help",
    "Let's track together",
    "Morsel mode: ON",
    "Healthy choices!",
    "You've got this!",
    "Craving control 💪",
    "Small bites, big wins"
  ]

  var body: some View {
    ZStack {
      VStack {
        // Main bubble
        Text(currentText)
          .font(MorselFont.body)
          .foregroundStyle(.white)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .glassEffect(.clear)
          .opacity(showMainBubble ? 1 : 0)
          .scaleEffect(showMainBubble ? 1 : 0.8)
          .offset(x: 0, y: -2)

        // Medium bubble
        Circle()
          .frame(width: 32, height: 32)
          .glassEffect(.clear)
          .opacity(showMediumBubble ? 1 : 0)
          .scaleEffect(showMediumBubble ? 1 : 0.8)
          .offset(x: 60, y: 2)

        // Small bubble
        Circle()
          .frame(width: 24, height: 24)
          .glassEffect(.clear)
          .opacity(showSmallBubble ? 1 : 0)
          .scaleEffect(showSmallBubble ? 1 : 0.8)
          .offset(x: 40, y: 0)
      }
    }
    .onAppear {
      startBubbleLoop()
    }
  }

  private func startBubbleLoop() {
    showSmallBubble = false
    showMediumBubble = false
    showMainBubble = false

    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
      bubbleCycle()
    }
  }

  private func bubbleCycle() {
    currentText = phrases.randomElement() ?? "Hi there!"

    // Animate in: small → medium → main
    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
      showSmallBubble = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
        showMediumBubble = true
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
        showMainBubble = true
      }
    }

    // Pause for 3s, then animate out: main → medium → small
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
        showMainBubble = false
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
          showMediumBubble = false
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
          showSmallBubble = false
        }
      }

      // Clear text after fade-out, then restart loop
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        currentText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          bubbleCycle()
        }
      }
    }
  }
}

#Preview {
  VStack {
    Spacer()
    MorselView(
      shouldOpen: .constant(false),
      shouldClose: .constant(false),
      isChoosingDestination: .constant(false),
      destinationProximity: .constant(0),
      isLookingUp: .constant(false),
      morselColor: .blue,
      supportsOpen: true
    ) { _ in }
#if os(iOS)
      .background(Color(.black))
#endif
    Spacer()
  }
  .frame(maxWidth: .infinity)
  .background(.black)
}
