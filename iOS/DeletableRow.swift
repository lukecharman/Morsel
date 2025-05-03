import SwiftUI

struct DeletableRow<Content: View>: View {
  let onDelete: () -> Void
  @ViewBuilder let content: () -> Content

  @State private var offset: CGFloat = 0
  @GestureState private var isDragging = false
  @State private var crossedThreshold = false
  @State private var animatePulse = false

  private let deleteThreshold: CGFloat = -80

  var body: some View {
    ZStack {
      content()
        .offset(x: offset)
        .simultaneousGesture(
          DragGesture()
            .onChanged { value in
              let horizontal = abs(value.translation.width)
              let vertical = abs(value.translation.height)

              // Only respond if it's mostly horizontal
              guard horizontal > vertical else { return }

              offset = min(0, value.translation.width)

              let hasCrossed = offset < deleteThreshold
              if hasCrossed && !crossedThreshold {
                crossedThreshold = true
                triggerPulse()
              } else if !hasCrossed && crossedThreshold {
                crossedThreshold = false
              }
            }
            .onEnded { value in
              if offset < deleteThreshold {
                withAnimation(.easeInOut) {
                  onDelete()
                }
              } else {
                withAnimation(.spring()) {
                  offset = 0
                }
              }
            }
        )

      // Trash icon
      HStack {
        Spacer()
        Image(systemName: "trash")
          .foregroundColor(.red)
          .padding(.trailing, 16)
          .scaleEffect(animatePulse ? 1.4 : 1.0)
          .opacity(trashIconOpacity)
          .offset(x: trashIconOffset)
          .animation(.easeOut(duration: 0.2), value: offset)
      }
    }
  }

  private func triggerPulse() {
    animatePulse = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      animatePulse = false
    }
  }

  private var trashIconOpacity: Double {
    let threshold: CGFloat = -20
    return offset < threshold ? Double(min(abs(offset + threshold) / 40, 1)) : 0
  }

  private var trashIconOffset: CGFloat {
    return max(0, 40 + offset * 0.5)
  }
}

