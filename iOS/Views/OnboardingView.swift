import SwiftUI

struct OnboardingView: View {
  var pages: [String] = ["Page 1", "Page 2", "Page 3"]
  var onClose: () -> Void

  @State private var currentPage = 0

  var body: some View {
    VStack {
      TabView(selection: $currentPage) {
        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
          VStack {
            Spacer()
            Text(page)
            Spacer()
            if index == pages.count - 1 {
              Button("Close") {
                onClose()
              }
              .padding()
            } else {
              Button("Next") {
                withAnimation {
                  currentPage = min(currentPage + 1, pages.count - 1)
                }
              }
              .padding()
            }
          }
          .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .always))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
    .ignoresSafeArea()
  }
}

#Preview {
  OnboardingView(onClose: {})
}
