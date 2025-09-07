import SwiftUI

struct BottomControlsView: View {
  @Binding var currentPageIndex: Int
  let pageCount: Int
  let morselColor: Color
  let onClose: () -> Void

  var body: some View {
    VStack {
      Spacer()
      HStack(spacing: 24) {
        Button(action: previous) {
          Image(systemName: "chevron.left")
            .font(.title3)
            .foregroundStyle(morselColor)
            .frame(width: 44, height: 44)
        }
        .opacity(canGoPrevious ? 1 : 0.4)
        .disabled(!canGoPrevious)
        .accessibilityLabel("Previous period")

        Button(action: onClose) {
          Image(systemName: "xmark")
            .font(.title3)
            .foregroundStyle(morselColor)
            .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Close digest")

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
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(
        Capsule(style: .continuous)
          .fill(Color.clear)
          .glassEffect(.clear, in: Capsule(style: .continuous))
      )
    }
  }

  private var canGoPrevious: Bool { currentPageIndex < pageCount - 1 }
  private var canGoNext: Bool { currentPageIndex > 0 }

  private func previous() {
    withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
      currentPageIndex = min(currentPageIndex + 1, pageCount - 1)
    }
  }

  private func next() {
    withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
      currentPageIndex = max(currentPageIndex - 1, 0)
    }
  }
}
