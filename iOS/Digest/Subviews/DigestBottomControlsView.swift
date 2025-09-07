import SwiftUI

struct DigestBottomControlsView: View {
  @Binding var currentPageIndex: Int

  let pageCount: Int
  let morselColor: Color
  let onClose: () -> Void

  var body: some View {
    VStack {
      Spacer()
      HStack(spacing: 24) {
        previousButton
        closeButton
        nextButton
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .glassCapsuleBackground()
    }
  }
}

private extension DigestBottomControlsView {
  var canGoPrevious: Bool {
    currentPageIndex < pageCount - 1
  }

  var canGoNext: Bool {
    currentPageIndex > 0
  }

  var previousButton: some View {
    Button(action: previous) {
      Image(systemName: "chevron.left")
        .font(.title3)
        .foregroundStyle(morselColor)
        .frame(width: 44, height: 44)
    }
    .opacity(canGoPrevious ? 1 : 0.4)
    .disabled(!canGoPrevious)
    .accessibilityLabel("Previous period")
  }

  var closeButton: some View {
    Button(action: onClose) {
      Image(systemName: "xmark")
        .font(.title3)
        .foregroundStyle(morselColor)
        .frame(width: 44, height: 44)
    }
    .accessibilityLabel("Close digest")
  }

  var nextButton: some View {
    Button(action: next) {
      Image(systemName: "chevron.right")
        .font(.title3)
        .foregroundStyle(morselColor)
        .frame(width: 44, height: 44)
    }
    .opacity(canGoNext ? 1 : 0.4)
    .disabled(!canGoNext)
    .accessibilityLabel("Next period")
  }

  func previous() {
    withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
      currentPageIndex = min(currentPageIndex + 1, pageCount - 1)
    }
  }

  func next() {
    withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
      currentPageIndex = max(currentPageIndex - 1, 0)
    }
  }
}
