import SwiftUI
import CoreMorsel

private struct OnboardingPage {
  let title: String
  let message: String
  let bubble: String?
}

struct OnboardingView: View {
  private let pages: [OnboardingPage] = [
    OnboardingPage(
      title: "Meet Morsel",
      message: "Your mindful eating companion who helps you handle cravings.",
      bubble: nil
    ),
    OnboardingPage(
      title: "Feed Your Cravings",
      message: "Tap Morsel when a craving hits and give it a name to stay aware.",
      bubble: nil
    ),
    OnboardingPage(
      title: "Digest Your Progress",
      message: "Review patterns and celebrate wins in the Digest and Stats views.",
      bubble: nil
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

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width

      ZStack {
        VStack(spacing: 24) {
          titleView()
            .font(MorselFont.title)
            .foregroundStyle(appSettings.morselColor)
          messageView()
            .font(MorselFont.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.bottom, 72)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        // Anchor text above page dots and controls
        .padding(.bottom, geo.safeAreaInsets.bottom + 104)
        .contentShape(Rectangle())
        .gesture(
          DragGesture()
            .onChanged { value in
              if !isDragging {
                isDragging = true
                dragAnchorPage = currentPage
              }
              // Positive when swiping left (toward next page)
              let deltaPages = -Double(value.translation.width / width)
              let target: Double = Double(dragAnchorPage) + deltaPages
              let clamped = min(max(target, 0.0), Double(pages.count - 1))

              // Wrap in an animated transaction so transitions run during drag
              withAnimation(.easeInOut(duration: 0.2)) {
                page = clamped
              }
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
            }
        )

        // Centered bottom controls in a glass container
        VStack {
          Spacer()
          HStack(spacing: 24) {
            Button(action: {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                currentPage = max(currentPage - 1, 0)
                page = Double(currentPage)
              }
            }) {
              Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .opacity(currentPage == 0 ? 0.4 : 1)
            .disabled(currentPage == 0)

            Button(action: {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                if currentPage == pages.count - 1 {
                  onClose()
                  Haptics.trigger(.success)
                } else {
                  currentPage = min(currentPage + 1, pages.count - 1)
                  page = Double(currentPage)
                }
              }
            }) {
              // Change the right control icon when on the last page
              Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "chevron.right")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
                .contentTransition(.symbolEffect)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            Capsule(style: .continuous)
              .fill(Color.clear)
              .glass(.clear, in: Capsule(style: .continuous))
          )
          .padding(.bottom, geo.safeAreaInsets.bottom + 24)
        }
        .frame(width: geo.size.width, height: geo.size.height)

        VStack {
          Spacer()
          HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
              Circle()
                .fill(
                  index == displayedIndex
                    ? appSettings.morselColor
                    : appSettings.morselColor.opacity(0.3)
                )
                .frame(width: 8, height: 8)
            }
          }
          .padding(.bottom, geo.safeAreaInsets.bottom + 128)
        }
        .frame(width: geo.size.width, height: geo.size.height)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .ignoresSafeArea()
    .onAppear {
      if !didSpeakGreeting {
        if let bubble = pages[0].bubble {
          onSpeak(bubble)
        }
        didSpeakGreeting = true
      }
      page = Double(currentPage)
    }
    .onChange(of: displayedIndex) { _, newValue in
      Haptics.trigger(.light)
    }
    .onChange(of: currentPage) { _, newValue in
      // Speak a friendly bubble line on each page change when present
      let index = max(0, min(pages.count - 1, newValue))
      if let bubble = pages[index].bubble {
        onSpeak(bubble)
      }
    }
  }
}

// MARK: - Private helpers

private extension OnboardingView {
  // Drive what we show off the live (rounded) page value so it updates during drag.
  var displayedIndex: Int {
    max(0, min(pages.count - 1, Int(round(page))))
  }

  @ViewBuilder
  func titleView() -> some View {
    Text(pages[displayedIndex].title)
      .id(displayedIndex)
      .transition(.blurReplace)
      .animation(.easeInOut(duration: 0.2), value: displayedIndex)
  }

  @ViewBuilder
  func messageView() -> some View {
    Text(pages[displayedIndex].message)
      .id(displayedIndex)
      .transition(.blurReplace)
      .animation(.easeInOut(duration: 0.2), value: displayedIndex)
  }
}

#Preview {
  OnboardingView(page: .constant(0), onClose: {})
}
