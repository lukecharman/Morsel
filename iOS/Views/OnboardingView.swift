import SwiftUI

@MainActor
struct OnboardingView: View {
  let pages: Int
  var onFinish: () -> Void

  @State private var currentPage = 0

  var body: some View {
    VStack {
      TabView(selection: $currentPage) {
        ForEach(0..<pages, id: \.self) { index in
          VStack {
            Spacer()
            Text("Page \(index + 1)")
              .font(.title)
            Spacer()
          }
          .tag(index)
        }
      }
      .tabViewStyle(.page)

      HStack {
        if currentPage > 0 {
          Button("Back") {
            withAnimation { currentPage -= 1 }
          }
        }
        Spacer()
        if currentPage < pages - 1 {
          Button("Next") {
            withAnimation { currentPage += 1 }
          }
        } else {
          Button("Close") { onFinish() }
        }
      }
      .padding()
    }
    .interactiveDismissDisabled()
  }
}

#Preview {
  OnboardingView(pages: 3, onFinish: {})
}

