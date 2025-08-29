import SwiftUI

// MARK: - Positioning Anchor

public struct MorselAnchor: Equatable {
  public enum Edge: Equatable {
    case top
    case bottom
    case left
    case right
  }

  public var edge: Edge
  public var padding: CGFloat

  public init(edge: Edge, padding: CGFloat) {
    self.edge = edge
    self.padding = padding
  }
}

public enum MorselDebugControlMode {
  case automatic
  case manual
}

public struct MorselDebugBindings {
  public var isBlinking: Binding<Bool>?
  public var isSwallowing: Binding<Bool>?
  public var idleOffset: Binding<CGSize>?
  public var idleLookaroundOffset: Binding<CGFloat>?

  public init(
    isBlinking: Binding<Bool>? = nil,
    isSwallowing: Binding<Bool>? = nil,
    idleOffset: Binding<CGSize>? = nil,
    idleLookaroundOffset: Binding<CGFloat>? = nil
  ) {
    self.isBlinking = isBlinking
    self.isSwallowing = isSwallowing
    self.idleOffset = idleOffset
    self.idleLookaroundOffset = idleLookaroundOffset
  }
}

public struct AnimatedEyeView: View {
  @Binding var amount: CGFloat
  @Binding var angle: Angle

  public init(amount: Binding<CGFloat>, angle: Binding<Angle>) {
    _amount = amount
    _angle = angle
  }

  public var body: some View {
    EyebrowedEyeShape(eyebrowAmount: amount, angle: angle)
      .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
      .animation(.easeInOut(duration: 0.3), value: amount)
  }
}

public struct EyebrowedEyeShape: Shape {
  public var eyebrowAmount: CGFloat // 0 = circle, 1 = flat segment
  public var angle: Angle // angle of flat segment

  public init(eyebrowAmount: CGFloat, angle: Angle) {
    self.eyebrowAmount = eyebrowAmount
    self.angle = angle
  }

  public var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get { AnimatablePair(eyebrowAmount, CGFloat(angle.degrees)) }
    set {
      eyebrowAmount = newValue.first
      angle = .degrees(Double(newValue.second))
    }
  }

  public func path(in rect: CGRect) -> Path {
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


public struct MorselView: View {
  @Binding var shouldOpen: Bool
  @Binding var shouldClose: Bool
  @Binding var isChoosingDestination: Bool
  @Binding var destinationProximity: CGFloat
  @Binding var isLookingUp: Bool
  @Binding var isOnboardingVisible: Bool
  @Binding var onboardingPage: Double
  @ObservedObject var speaker: MorselSpeaker

  @EnvironmentObject var appSettings: AppSettings

  @State private var isOpen = false
  @State private var isSwallowingInternal = false
  @State private var isBlinkingInternal = false
  @State private var idleOffsetInternal: CGSize = .zero
  @State private var idleLookaroundOffsetInternal: CGFloat = .zero
  @State private var isBeingTouched = false
  @State private var text: String = ""
  @State private var playSpeechBubbleAnimation = false
  @State private var isTalking = false
  @State private var talkingHeightDelta: CGFloat = 0
  @State private var storedAnchorBeforeOnboarding: MorselAnchor?

  @State private var didTriggerLongPress = false

  @State private var dragOffset: CGSize = .zero

  @FocusState private var isFocused: Bool

  // Controls on-screen positioning
  @Binding var anchor: MorselAnchor?

  var morselColor: Color
  var supportsOpen: Bool = true

  var onTap: (() -> Void)? = nil
  var onAdd: (String) -> Void

  var debugBindings: MorselDebugBindings? = nil
  var debugControlMode: MorselDebugControlMode = .automatic

  public init(
    shouldOpen: Binding<Bool>,
    shouldClose: Binding<Bool>,
    isChoosingDestination: Binding<Bool>,
    destinationProximity: Binding<CGFloat>,
    isLookingUp: Binding<Bool>,
    isOnboardingVisible: Binding<Bool> = .constant(false),
    onboardingPage: Binding<Double> = .constant(0),
    speaker: MorselSpeaker = .init(),
    anchor: Binding<MorselAnchor?> = .constant(nil),
    morselColor: Color,
    supportsOpen: Bool = true,
    onTap: (() -> Void)? = nil,
    onAdd: @escaping (String) -> Void,
    debugBindings: MorselDebugBindings? = nil,
    debugControlMode: MorselDebugControlMode = .automatic
  ) {
    _shouldOpen = shouldOpen
    _shouldClose = shouldClose
    _isChoosingDestination = isChoosingDestination
    _destinationProximity = destinationProximity
    _isLookingUp = isLookingUp
    _isOnboardingVisible = isOnboardingVisible
    _onboardingPage = onboardingPage
    self.speaker = speaker
    _anchor = anchor
    self.morselColor = morselColor
    self.supportsOpen = supportsOpen
    self.onTap = onTap
    self.onAdd = onAdd
    self.debugBindings = debugBindings
    self.debugControlMode = debugControlMode
  }

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

  public var body: some View {
    GeometryReader { _ in
      content
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignmentForAnchor)
        .padding(paddingForAnchor)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: anchor)
    }
    .ignoresSafeArea(edges: ignoredSafeAreaEdges)
    .onAppear {
      startBlinking()
      startIdleWiggle()
    }
    .onChange(of: isOnboardingVisible) { oldValue, newValue in
      if newValue {
        // Capture the current anchor before onboarding moves/scales Morsel
        storedAnchorBeforeOnboarding = anchor
      } else {
        // Restore anchor and neutral pose when onboarding closes
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
          anchor = storedAnchorBeforeOnboarding ?? MorselAnchor(edge: .bottom, padding: 6)
          isOpen = false
          isBeingTouched = false
        }
        // Reset subtle offsets to avoid drifting from the original position
        withAnimation(.easeInOut(duration: 0.2)) {
          idleOffsetInternal = .zero
          idleLookaroundOffsetInternal = 0
          dragOffset = .zero
        }
      }
    }
    .onChange(of: speaker.message) { _, newValue in
      if newValue != nil {
        playSpeechBubbleAnimation = true
        if let text = newValue {
          startTalking(totalDuration: readingDuration(for: text))
        } else {
          startTalking(totalDuration: 2.6)
        }
      }
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
    .onChange(of: onboardingPage) { oldValue, newValue in
      let oldPage = Int(round(oldValue))
      let newPage = Int(round(newValue))
      guard oldPage != newPage else { return }

      switch newPage {
      case 0:
        withAnimation { isOpen = false }
        anchor = MorselAnchor(edge: .bottom, padding: 48)
        isFocused = false
        isSwallowingInternal = false
      case 1:
        withAnimation { isOpen = true }
        isFocused = false
      case 2:
        close()
      default:
        break
      }
    }
  }

  private var content: some View {
    VStack(spacing: 8) {
      SpeechBubble(
        isOpen: $isOpen,
        isBeingTouched: $isBeingTouched,
        playAnimation: $playSpeechBubbleAnimation,
        message: $speaker.message,
        tailOnLeft: tailOnLeft,
        placeBelow: shouldPlaceBubbleBelow
      )
      // Keep the bubble away from the scaled face
      .padding(shouldPlaceBubbleBelow ? .top : .bottom, bubbleAvoidancePadding)
      face
        .scaleEffect(contentScale)
        .animation(.easeInOut(duration: 0.2), value: onboardingPage)
    }
    .offset(dragOffset)
    .offset(faceOffset)
  }

  private var contentScale: CGFloat {
    if isChoosingDestination { return 2 }
    if isOnboardingVisible { return max(1, min(2, 2 - 0.5 * onboardingPage)) }
    return 1
  }

  // Estimated face height used to separate the bubble when scaling
  private var faceBaseHeight: CGFloat {
    if isOpen {
      return 120
    } else {
      return .lerp(from: 64, to: 80, by: happinessLevel)
    }
  }

  // How much extra space the bubble should keep from the face as it scales
  private var bubbleAvoidancePadding: CGFloat {
    let scale = contentScale
    guard scale > 1 else { return 0 }
    // Face scales around its center; the top edge moves up by ~((s-1) * h / 2)
    return (scale - 1) * (faceBaseHeight / 2)
  }

  private var tailOnLeft: Bool {
    guard let anchor else { return false }
    switch anchor.edge {
    case .right: return true
    case .left: return false
    default: return false
    }
  }

  private var shouldPlaceBubbleBelow: Bool {
    if let anchor, anchor.edge == .top { return true }
    if isOnboardingVisible {
      return faceOffset.height < -300
    }
    return false
  }

  var faceOffset: CGSize {
    if isOnboardingVisible {
      let pageIndex = Int(round(onboardingPage))
      switch pageIndex {
      case 0:
        return CGSize(width: 0, height: -300)
      case 1:
        return CGSize(width: 0, height: -380)
      case 2:
        // Lift Morsel higher on page 3 to avoid overlapping text
        return CGSize(width: 0, height: -320)
      default:
        return CGSize(width: 0, height: -320)
      }
    } else {
      return isOpen ? .zero : idleOffset
    }
  }

  var face: some View {
    let baseColor = morselColor
    let topColor = Color(adjustedTopColor(from: UIColor(baseColor), sadness: sadnessLevel, happiness: happinessLevel))

    return ZStack {
//      Color.clear
//        .frame(width: 240, height: 64)
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
      .gesture(
        supportsOpen ?
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            dragOffset = CGSize(width: value.translation.width * 0.35, height: value.translation.height * 0.35)
            if !isBeingTouched && !isChoosingDestination {
              withAnimation {
                isBeingTouched = true
              }
            }
          }
          .onEnded { _ in
            if !didTriggerLongPress {
              withAnimation {
                isBeingTouched = false
              }
              if !isChoosingDestination && !isOnboardingVisible {
                onTap?()

                if isOpen {
                  close()
                } else {
                  open()
                }
              }
            }
            didTriggerLongPress = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
              dragOffset = .zero
            }
          }
        : nil
      )
      .simultaneousGesture(
        LongPressGesture(minimumDuration: 0.6)
          .onEnded { _ in
            guard !isOnboardingVisible && !isChoosingDestination else { return }

            didTriggerLongPress = true
            playSpeechBubbleAnimation = true
            // Animate mouth even when using a random phrase bubble
            startTalking(totalDuration: 2.6)
          }
      )
    }
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
  }

  // MARK: - Anchor helpers

  private var alignmentForAnchor: Alignment {
    guard let anchor else { return .center }
    switch anchor.edge {
    case .top: return .top
    case .bottom: return .bottom
    case .left: return .leading
    case .right: return .trailing
    }
  }

  private var paddingForAnchor: EdgeInsets {
    guard let anchor else { return EdgeInsets() }
    switch anchor.edge {
    case .top: return EdgeInsets(top: anchor.padding, leading: 0, bottom: 0, trailing: 0)
    case .bottom: return EdgeInsets(top: 0, leading: 0, bottom: anchor.padding, trailing: 0)
    case .left: return EdgeInsets(top: 0, leading: anchor.padding, bottom: 0, trailing: 0)
    case .right: return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: anchor.padding)
    }
  }

  private var ignoredSafeAreaEdges: Edge.Set {
    guard let anchor, anchor.padding == 0 else { return [] }
    switch anchor.edge {
    case .top: return [.top]
    case .bottom: return [.bottom]
    case .left: return [.leading]
    case .right: return [.trailing]
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
        height: isOpen
          ? 74
          : (.lerp(from: 8, to: 30, by: happinessLevel) + (isTalking ? talkingHeightDelta : 0))
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
      .allowsHitTesting(!isOnboardingVisible && !isChoosingDestination)
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
      anchor = nil
    }
  }

  func close() {
    withAnimation {
      text = ""
      isOpen = false
      shouldClose = false
      isFocused = false
      anchor = MorselAnchor(edge: .bottom, padding: 6)
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

  func startTalking(totalDuration: Double) {
    isTalking = true
    var elapsed: Double = 0
    let interval: Double = 0.12
    let total: Double = max(1.6, min(totalDuration, 7.0))
    Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
      elapsed += interval

      // Subtle height-only variation for a less intense look
      let targetHeight = CGFloat.random(in: 1...3)

      withAnimation(.easeInOut(duration: Double.random(in: 0.08...0.14))) {
        talkingHeightDelta = targetHeight
      }

      if elapsed >= total {
        timer.invalidate()
        withAnimation(.easeInOut(duration: 0.2)) {
          isTalking = false
          talkingHeightDelta = 0
        }
      }
    }
  }

  func readingDuration(for text: String) -> Double {
    // Estimate by words, with a floor/ceiling to feel snappy
    let words = text.split { $0.isWhitespace || $0.isNewline }.count
    // Base 1.6s + 0.25s per word, clamped
    let duration = 1.6 + 0.25 * Double(words)
    return max(1.8, min(duration, 7.0))
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

public struct SpeechBubble: View {
  @Binding var isOpen: Bool
  @Binding var isBeingTouched: Bool
  @Binding var playAnimation: Bool
  @Binding var message: String?
  var tailOnLeft: Bool = false
  var placeBelow: Bool = false

  @Namespace var union

  @State private var currentText = ""
  @State private var showSmallBubble = false
  @State private var showMediumBubble = false
  @State private var showMainBubble = false

  public init(
    isOpen: Binding<Bool>,
    isBeingTouched: Binding<Bool>,
    playAnimation: Binding<Bool>,
    message: Binding<String?>,
    tailOnLeft: Bool = false,
    placeBelow: Bool = false
  ) {
    _isOpen = isOpen
    _isBeingTouched = isBeingTouched
    _playAnimation = playAnimation
    _message = message
    self.tailOnLeft = tailOnLeft
    self.placeBelow = placeBelow
  }

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

  public var body: some View {
    ZStack {
      if placeBelow {
        // Tail points upward (circles above), bubble below the face
        VStack(spacing: 0) {
          // Tail circles
          Circle()
            .frame(width: 24, height: 24)
            .glass(.clear)
            .opacity(showSmallBubble ? 1 : 0)
            .scaleEffect(showSmallBubble ? 1 : 0.8)
            .offset(x: tailOnLeft ? -40 : 40, y: -4)

          Circle()
            .frame(width: 32, height: 32)
            .glass(.clear)
            .opacity(showMediumBubble ? 1 : 0)
            .scaleEffect(showMediumBubble ? 1 : 0.8)
            .offset(x: tailOnLeft ? -60 : 60, y: -2)

          // Main bubble
          Text(currentText)
            .font(MorselFont.body)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glass(.clear)
            .frame(maxWidth: 320)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(showMainBubble ? 1 : 0)
            .scaleEffect(showMainBubble ? 1 : 0.8)
            .offset(x: 0, y: -2)
        }
      } else {
        // Tail points downward (circles below), bubble above the face
        VStack(spacing: 0) {
          // Main bubble
          Text(currentText)
            .font(MorselFont.body)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glass(.clear)
            .frame(maxWidth: 320)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(showMainBubble ? 1 : 0)
            .scaleEffect(showMainBubble ? 1 : 0.8)
            .offset(x: 0, y: -2)

          // Tail circles
          Circle()
            .frame(width: 32, height: 32)
            .glass(.clear)
            .opacity(showMediumBubble ? 1 : 0)
            .scaleEffect(showMediumBubble ? 1 : 0.8)
            .offset(x: tailOnLeft ? -60 : 60, y: 2)

          Circle()
            .frame(width: 24, height: 24)
            .glass(.clear)
            .opacity(showSmallBubble ? 1 : 0)
            .scaleEffect(showSmallBubble ? 1 : 0.8)
            .offset(x: tailOnLeft ? -40 : 40, y: 0)
        }
      }
    }
    .onChange(of: playAnimation) { _, newValue in
      if newValue {
        bubbleCycle()
      }
    }
  }

  private func bubbleCycle() {
    currentText = message ?? phrases.randomElement() ?? "Hi there!"

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

    // Pause based on text length, then animate out: main → medium → small
    let hold = readingDuration(for: currentText)
    DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
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

      // Clear text after fade-out, then reset playAnimation flag
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        currentText = ""
        playAnimation = false
        message = nil
      }
    }
  }

  private func readingDuration(for text: String) -> Double {
    let words = text.split { $0.isWhitespace || $0.isNewline }.count
    // Base + per-word; keep within pleasant bounds
    let duration = 1.6 + 0.25 * Double(words)
    return max(1.8, min(duration, 7.0))
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
