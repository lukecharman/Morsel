import SwiftUI

struct MouthAddButton: View {
  @State private var isOpen = false
  @State private var isSwallowing = false
  @State private var text: String = ""

  @FocusState private var isFocused: Bool

  var onAdd: (String) -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      face
        .rotation3DEffect(
          .degrees(isSwallowing ? -8 : 0),
          axis: (x: 1, y: 0, z: 0),
          anchor: .center,
          perspective: 0.5
        )
        .overlay(facialFeatures)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: isOpen)
        .onTapGesture { isOpen ? close() : open() }
    }
    .padding()
  }

  var face: some View {
    UnevenRoundedRectangle(
      cornerRadii: .init(
        topLeading: isOpen ? 120 : 64,
        bottomLeading: isOpen ? 32 : 32,
        bottomTrailing: isOpen ? 32 : 32,
        topTrailing: isOpen ? 120 : 64
      ),
      style: .continuous
    )
    .fill(Color.accentColor)
    .frame(
      width: isOpen ? 240 : 86,
      height: isOpen ? 120 : 64
    )
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
      mouth
        .rotation3DEffect(
          .degrees(isSwallowing ? -8 : 0),
          axis: (x: 1, y: 0, z: 0),
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
      Circle()
        .fill(Color(uiColor: UIColor(red: 0.07, green: 0.20, blue: 0.37, alpha: 1.00)))
        .frame(width: 10, height: 10)
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
      textField
    }
  }

  var textField: some View {
    TextField("", text: $text)
      .onSubmit {
        onAdd(text)
        close()
      }
      .tint(.white)
      .focused($isFocused)
      .foregroundStyle(Color.white)
      .allowsHitTesting(isOpen)
      .opacity(isOpen ? 1 : 0)
      .frame(width: isOpen ? 160 : 0, height: isOpen ? 72 : 0)
      .multilineTextAlignment(.center)
      .backgroundStyle(Color.black.opacity(0.5))
      .scaleEffect(isOpen ? CGSize(width: 1, height: 1) : .zero)
      .offset(y: isOpen ? 14 : 32)
  }

  func open() {
    withAnimation {
      isOpen = true
      isFocused = true
    }
  }

  func close() {
    withAnimation {
      text = ""
      isOpen = false
      isFocused = false
      isSwallowing = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      withAnimation {
        isSwallowing = false
      }
    }
  }
}

#Preview {
  MouthAddButton { _ in }
    .background(Color(.systemBackground))
}
