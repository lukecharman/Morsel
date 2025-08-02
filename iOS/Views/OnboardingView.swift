import SwiftUI

struct OnboardingView: View {
  var onDone: () -> Void

  var body: some View {
    VStack {
      Spacer()
      Button("Done with onboarding") {
        onDone()
      }
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

