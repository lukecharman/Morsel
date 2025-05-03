import SwiftUI

struct DeletableRow<Content: View>: View {
  @Binding var isDraggingHorizontally: Bool

  let onDelete: () -> Void
  @ViewBuilder let content: () -> Content

  @State private var offset: CGFloat = 0
  @GestureState private var isDragging = false
  @State private var crossedThreshold = false

  private let deleteThreshold: CGFloat = -80

  var body: some View {
    ZStack {
      content()
        .offset(x: offset)
        .background(Color.clear)
        .simultaneousGesture(
          DragGesture()
            .onChanged { value in
              let horizontal = abs(value.translation.width)
              let vertical = abs(value.translation.height)

              if horizontal > vertical && horizontal > 10 {
                isDraggingHorizontally = true
              } else if vertical > horizontal && vertical > 10 {
                isDraggingHorizontally = false
              }

              // Only respond if it's mostly horizontal
              guard horizontal > vertical else { return }

              offset = min(0, value.translation.width)

              let hasCrossed = offset < deleteThreshold
              if hasCrossed && !crossedThreshold {
                crossedThreshold = true
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
        Image(systemName: crossedThreshold ? "trash.fill" : "trash")
          .scaleEffect(crossedThreshold ? 1.3 : 1.0)
          .animation(.spring(response: 0.3, dampingFraction: 0.5), value: crossedThreshold)
          .foregroundColor(.red)
          .padding(.trailing, 16)
          .opacity(trashIconOpacity)
          .offset(x: trashIconOffset)
          .animation(.easeOut(duration: 0.2), value: offset)
      }
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

