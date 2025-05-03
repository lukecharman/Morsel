import SwiftUI

struct BottomOverlayBar: View {
  var onStatsTap: () -> Void
  var onExtrasTap: () -> Void
  var onAdd: (String) -> Void

  @Binding var shouldOpenMouth: Bool

  @State private var isMouthOpen = false

  var body: some View {
    ZStack {
      // Morsel in the centre
      MouthAddButton(
        shouldOpen: $shouldOpenMouth,
        isOpen: $isMouthOpen,
        onAdd: onAdd
      )

      HStack {
        ZStack {
          Circle()
            .foregroundStyle(Material.bar)
            .frame(width: 44, height: 44)
            .shadow(radius: 8)
          Button(action: onStatsTap) {
            Image(systemName: "chart.bar.xaxis")
          }
        }
        Spacer()
      }
      .padding(.leading, 72)
      .opacity(isMouthOpen ? 0 : 1)
      .disabled(isMouthOpen)

      HStack {
        Spacer()
        ZStack {
          Circle()
            .foregroundStyle(Material.bar)
            .frame(width: 44, height: 44)
            .shadow(radius: 8)
          Button(action: onExtrasTap) {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
      .padding(.trailing, 72)
      .opacity(isMouthOpen ? 0 : 1)
      .disabled(isMouthOpen)
    }
    .frame(height: 100)
    .padding(.bottom, 16)
  }
}

