import SwiftUI

struct DeletableRowView<Content: View>: View {
  @Binding var isDraggingHorizontally: Bool

  let onDelete: () -> Void
  @ViewBuilder let content: () -> Content

  @State private var offset: CGFloat = 0
  @GestureState private var isDragging = false
  @State private var crossedThreshold = false

  @State private var hasLockedDirection = false
  @State private var isHorizontalGesture = false

  private let deleteThreshold: CGFloat = -80

  var body: some View {
    ZStack {
      Rectangle()
        .foregroundColor(.clear)
        .contentShape(Rectangle())

      content()
        .offset(x: offset)
        .simultaneousGesture(
          DragGesture()
            .onChanged { value in
              let dx = value.translation.width
              let dy = value.translation.height

              if !hasLockedDirection {
                let angle = abs(atan2(dy, dx)) * 180 / .pi
                isHorizontalGesture = angle < 30 || angle > 150
                hasLockedDirection = true
                isDraggingHorizontally = isHorizontalGesture
              }

              guard isHorizontalGesture else { return }

              offset = min(0, dx)

              let hasCrossed = offset < deleteThreshold
              if hasCrossed && !crossedThreshold {
                crossedThreshold = true
                Haptics.trigger(.medium)
              } else if !hasCrossed && crossedThreshold {
                crossedThreshold = false
              }

              Haptics.prepare(.success)
            }
            .onEnded { value in
              defer {
                hasLockedDirection = false
                isHorizontalGesture = false
              }

              guard isHorizontalGesture else { return }

              if offset < deleteThreshold {
                Haptics.trigger(.success)
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

