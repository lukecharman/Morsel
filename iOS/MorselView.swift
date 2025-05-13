import SwiftUI

struct MorselView: View {
  @Binding var shouldOpen: Bool
  @Binding var shouldClose: Bool
  @Binding var isChoosingDestination: Bool
  @Binding var destinationProximity: CGFloat

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
          .degrees(isSwallowing ? -20 : 0),
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
        .rotationEffect(.degrees(destinationProximity * 10))
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
        .shadow(radius: 10)
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
    ZStack {
      Color.clear.frame(width: 240, height: 86)
      UnevenRoundedRectangle(
        cornerRadii: .init(
          topLeading: isOpen ? 120 : 64,
          bottomLeading: isOpen ? 32 : 32,
          bottomTrailing: isOpen ? 32 : 32,
          topTrailing: isOpen ? 120 : 64
        ),
        style: .continuous
      )
      .fill(
        LinearGradient(
          colors: [
            Color(uiColor: AppSettings.shared.morselColor),
            Color(uiColor: AppSettings.shared.morselColor).opacity(0.9),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(
        width: isOpen ? 240 : 86,
        height: isOpen ? 120 : 64
      )
      .overlay(
        facialFeatures
      )
    }
  }

  var facialFeatures: some View {
    VStack {
      eyes
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
      mouth
        .scaleEffect(y: isSwallowing ? 0.8 : 1)
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
      Spacer()
    }
  }

  var eyes: some View {
    HStack(spacing: isOpen ? 24 : 12) {
      Circle()
        .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
        .frame(width: 10, height: 10)
        .scaleEffect(y: (isSwallowing || isBlinking) ? 0.25 : 1)
        .shadow(radius: 4)
      Circle()
        .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
        .frame(width: 10, height: 10)
        .scaleEffect(y: (isSwallowing || isBlinking) ? 0.25 : 1)
        .shadow(radius: 4)
    }
    .offset(y: 16)
  }

  var mouth: some View {
    ZStack {
      UnevenRoundedRectangle(
        cornerRadii: .init(
          topLeading: 16,
          bottomLeading: 48,
          bottomTrailing: 48,
          topTrailing: 16
        ),
        style: .continuous
      )
      .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
      .frame(width: isOpen ? 170 : 24, height: isOpen ? 74 : 8)
      .offset(y: isOpen ? 16 : 24)
      .shadow(radius: 10)
      textField
    }
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
    Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8), repeats: true) { _ in
      withAnimation(.easeInOut(duration: 1)) {
        idleLookaroundOffset = CGFloat.random(in: -15...15)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        withAnimation(.easeInOut(duration: 0.5)) {
          idleLookaroundOffset = 0
        }
      }
    }
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
