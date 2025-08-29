import SwiftUI
import CoreMorsel

private struct OnboardingPage {
  let title: String
  let message: String
}

struct OnboardingView: View {
  private let pages: [OnboardingPage] = [
    OnboardingPage(
      title: "Meet Morsel",
      message: "Your mindful eating companion who helps you handle cravings."
    ),
    OnboardingPage(
      title: "Feed Your Cravings",
      message: "Tap Morsel when a craving hits and give it a name to stay aware."
    ),
    OnboardingPage(
      title: "Digest Your Progress",
      message: "Review patterns and celebrate wins in the Digest and Stats views."
    )
  ]

  @EnvironmentObject var appSettings: AppSettings
  @Binding var page: Double
  var onClose: () -> Void
  var onSpeak: (String) -> Void = { _ in }

  @State private var currentPage = 0
  @State private var didSpeakGreeting = false
  @State private var isDragging = false
  @State private var dragAnchorPage = 0
  @State private var dragFraction: Double = 0
  @State private var dragDirection: Int = 0 // -1 = back, 1 = forward, 0 = none

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width

      ZStack {
        VStack(spacing: 24) {
          Spacer()
          titleView()
            .font(MorselFont.title)
            .foregroundStyle(appSettings.morselColor)
          messageView()
            .font(MorselFont.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.vertical, 56)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
          DragGesture()
            .onChanged { value in
              if !isDragging {
                isDragging = true
                dragAnchorPage = currentPage
                dragDirection = 0
                dragFraction = 0
              }
              // Positive when swiping left (toward next page)
              let deltaPages = -Double(value.translation.width / width)
              let target: Double = Double(dragAnchorPage) + deltaPages
              let clamped = min(max(target, 0.0), Double(pages.count - 1))
              page = clamped
              dragDirection = deltaPages == 0 ? 0 : (deltaPages > 0 ? 1 : -1)
              dragFraction = min(max(abs(deltaPages), 0.0), 1.0)
            }
            .onEnded { value in
              // Inertia + snap using predicted end position
              let predictedDeltaPages = -Double(value.predictedEndTranslation.width / width)
              let predicted = Double(dragAnchorPage) + predictedDeltaPages
              var targetIndex = Int(round(predicted))
              targetIndex = max(0, min(pages.count - 1, targetIndex))

              currentPage = targetIndex
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                page = Double(targetIndex)
              }

              isDragging = false
              dragFraction = 0
              dragDirection = 0
            }
        )

        // Bottom-left and bottom-right controls, positioned like Stats/Extras
        VStack {
          Spacer()
          HStack {
            ToggleButton(isActive: false, systemImage: "chevron.left") {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                currentPage = max(currentPage - 1, 0)
                page = Double(currentPage)
              }
            }
            .padding(.leading, 24)
            .opacity(currentPage == 0 ? 0 : 1)

            Spacer()

            ToggleButton(isActive: currentPage == pages.count - 1, systemImage: "chevron.right") {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                if currentPage == pages.count - 1 {
                  onClose()
                } else {
                  currentPage = min(currentPage + 1, pages.count - 1)
                  page = Double(currentPage)
                }
              }
            }
            .padding(.trailing, 24)
          }
          .padding(.bottom, geo.safeAreaInsets.bottom + 60)
        }
        .frame(width: geo.size.width, height: geo.size.height)

        VStack {
          Spacer()
          HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
              Circle()
                .fill(
                  index == Int(round(page))
                    ? appSettings.morselColor
                    : appSettings.morselColor.opacity(0.3)
                )
                .frame(width: 8, height: 8)
            }
          }
          .padding(.bottom, 24)
        }
        .frame(width: geo.size.width, height: geo.size.height)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
    .ignoresSafeArea()
    .onAppear {
      if !didSpeakGreeting {
        onSpeak("Hi, I'm Morsel!")
        didSpeakGreeting = true
      }
      page = Double(currentPage)
    }
  }
}

// MARK: - Private helpers

private extension OnboardingView {
  // Title: instant swap during drag (no crossfade, no per-character)
  @ViewBuilder
  func titleView() -> some View {
    if isDragging {
      let outgoingIndex = dragAnchorPage
      if dragDirection == 0 {
        Text(pages[outgoingIndex].title)
      } else {
        let incomingIndex: Int = dragDirection > 0
          ? min(dragAnchorPage + 1, pages.count - 1)
          : max(dragAnchorPage - 1, 0)
        // Instantly swap to the incoming title; no crossfade.
        Text(pages[incomingIndex].title)
      }
    } else {
      Text(pages[currentPage].title)
    }
  }

  // Body: reveal characters by coloring from clear -> primary while keeping layout stable
  @ViewBuilder
  func messageView() -> some View {
    if isDragging {
      if dragDirection == 0 {
        Text(pages[dragAnchorPage].message)
      } else {
        let incomingIndex: Int = dragDirection > 0
        ? min(dragAnchorPage + 1, pages.count - 1)
        : max(dragAnchorPage - 1, 0)
        let text = pages[incomingIndex].message
        let total = text.count
        let countToShow = Int((Double(total) * dragFraction).rounded(.toNearestOrAwayFromZero))
        let end = text.index(text.startIndex, offsetBy: min(max(countToShow, 0), total))
        let visible = String(text[..<end])

        ZStack(alignment: .topLeading) {
          // Full layout text in clear color to prevent shifting
          Text(text)
            .foregroundStyle(Color.primary.opacity(0))
          // Overlay visible portion in primary color
          Text(visible)
            .foregroundStyle(.primary)
        }
      }
    } else {
      Text(pages[currentPage].message)
    }
  }

  // (No other helpers)
}

#Preview {
  OnboardingView(page: .constant(0), onClose: {})
}
