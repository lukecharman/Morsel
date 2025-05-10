import SwiftUI

struct BottomBarView: View {
  @Binding var showStats: Bool
  @Binding var showExtras: Bool
  let isKeyboardVisible: Bool

  var body: some View {
    GeometryReader { geo in
      VStack {
        Spacer()
        HStack(spacing: 48) {
          if !showExtras {
            ToggleButton(
              isActive: showStats,
              systemImage: "chart.bar",
              action: {
                withAnimation {
                  toggleStats()
                }
              }
            )
            .padding(.leading, 24)
            .transition(.blurReplace)
          }

          Spacer()

          if !showStats {
            ToggleButton(
              isActive: showExtras,
              systemImage: "ellipsis",
              action: {
                withAnimation {
                  toggleExtras()
                }
              }
            )
            .padding(.trailing, 24)
            .transition(.blurReplace)
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, geo.safeAreaInsets.bottom + 60)
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
      }
      .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
    }
    .ignoresSafeArea()
  }

  private func toggleStats() {
    showStats.toggle()
    if showStats {
      showExtras = false
    }
  }

  private func toggleExtras() {
    showExtras.toggle()
    if showExtras {
      showStats = false
    }
  }
}
