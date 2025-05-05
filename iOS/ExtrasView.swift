import SwiftUI

struct ExtrasView: View {
  var body: some View {
    ScrollView {
      LazyVStack {
        Text("Extras")
      }
    }
    .safeAreaInset(edge: .bottom) {
      Spacer().frame(height: 160)
    }
    .frame(maxWidth: .infinity)
  }
}
