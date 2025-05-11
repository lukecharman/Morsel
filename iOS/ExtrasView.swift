import SwiftUI
import SwiftData

struct ExtrasView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var showClearAlert = false
  @State private var showClearFailedAlert = false
  @State private var showFeedbackAlert = false

  var onClearAll: () -> Void

  var body: some View {
    ScrollView {
      LazyVGrid(columns: [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
      ], spacing: 16) {
        CardView(title: "Clear all your data", value: "Reset", icon: "trash") { showClearAlert = true }
        CardView(title: "Got feedback?", value: "Feedback", icon: "ellipsis.message") { showFeedbackAlert = true }
      }
      .safeAreaInset(edge: .top) {
        Spacer().frame(height: 16)
      }
      .padding(.horizontal, 16)
    }
    .mask(
      LinearGradient(
        gradient: Gradient(stops: [
          .init(color: .clear, location: 0),
          .init(color: .black, location: 0.01),
          .init(color: .black, location: 0.925),
          .init(color: .clear, location: 0.955),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .alert("Are you sure?", isPresented: $showClearAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Yes", role: .destructive) {
        confirmClearData()
      }
    } message: {
      Text("This will remove all of your data. This action cannot be undone.")
    }
    .alert("Something went wrong", isPresented: $showClearFailedAlert) {
      Button("Okay", role: .cancel) { }
    } message: {
      Text("There was a problem clearing your data. Please try again later.")
    }
    .sheet(isPresented: $showFeedbackAlert) {
      FeedbackView()
        .onAppear {
          Analytics.track(ScreenViewFeedback())
        }
    }
    .onAppear {
      Analytics.track(ScreenViewExtras())
    }
  }

  func confirmClearData() {
    if modelContext.deleteAll(FoodEntry.self) {
      onClearAll()
    } else {
      showClearFailedAlert = true
    }
  }
}

#Preview {
  ExtrasView(onClearAll: {})
    .background(Color(.systemGroupedBackground))
}
