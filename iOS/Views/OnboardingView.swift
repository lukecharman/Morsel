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

  @State private var currentPage = 0

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width

      ZStack {
        TabView(selection: $currentPage) {
          ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
            VStack(spacing: 24) {
              Spacer()
              Text(page.title)
                .font(MorselFont.title)
                .foregroundStyle(appSettings.morselColor)
              Text(page.message)
                .font(MorselFont.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
              Spacer()
            }
            .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: currentPage) { newValue in
          withAnimation { page = Double(newValue) }
        }
        .simultaneousGesture(
          DragGesture()
            .onChanged { value in
              let progress = Double(currentPage) - Double(value.translation.width / width)
              page = min(max(progress, 0), Double(pages.count - 1))
            }
            .onEnded { _ in
              page = Double(currentPage)
            }
        )

        HStack {
          Button {
            withAnimation {
              currentPage = max(currentPage - 1, 0)
              page = Double(currentPage)
            }
          } label: {
            Image(systemName: "chevron.left")
              .frame(width: 44, height: 44)
          }
          .opacity(currentPage == 0 ? 0 : 1)

          Spacer()

          Button {
            withAnimation {
              if currentPage == pages.count - 1 {
                onClose()
              } else {
                currentPage = min(currentPage + 1, pages.count - 1)
                page = Double(currentPage)
              }
            }
          } label: {
            Image(systemName: currentPage == pages.count - 1 ? "xmark" : "chevron.right")
              .frame(width: 44, height: 44)
          }
        }
        .padding(.horizontal, 8)
        .frame(width: geo.size.width, height: geo.size.height)
        .foregroundStyle(.primary)

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
  }
}

#Preview {
  OnboardingView(page: .constant(0), onClose: {})
}

