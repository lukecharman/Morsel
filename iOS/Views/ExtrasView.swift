import CoreMorsel
import SwiftUI
import SwiftData

struct ExtrasView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var showClearAlert = false
  @State private var showClearFailedAlert = false
  @State private var showFeedbackAlert = false
  @State private var showColorSheet = false
  @State private var showIconSheet = false
  @State private var showThemeSheet = false

  var onClearAll: () -> Void
  var onShowOnboarding: () -> Void

#if DEBUG
  @State private var showDebugMenu = false
#endif

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        CardView(
          title: "",
          value: "Appearance",
          icon: "moon.circle.fill",
          description: "Choose between light, dark, or system appearance.",
          onTap: { showThemeSheet = true }
        )
        CardView(
          title: "",
          value: "Theme",
          icon: "theatermask.and.paintbrush.fill",
          description: "Pick a colour scheme for your Morsel and make it your own.",
          onTap: { showColorSheet = true }
        )
        CardView(
          title: "",
          value: "Icon",
          icon: "questionmark.app.dashed",
          description: "Choose a different app icon for Morsel.",
          onTap: { showIconSheet = true }
        )
        CardView(
          title: "",
          value: "Reset",
          icon: "trash",
          description: "This will permanently delete all your entries and cannot be undone.",
          onTap: { showClearAlert = true }
        )
        CardView(
          title: "",
          value: "Feedback",
          icon: "ellipsis.message",
          description: "Let us know how Morsel’s doing or what you'd like to see next.",
          onTap: { showFeedbackAlert = true }
        )
        CardView(
          title: "",
          value: "Onboarding",
          icon: "rectangle.fill.on.rectangle.fill",
          description: "View the onboarding again.",
          onTap: { onShowOnboarding() }
        )
#if DEBUG
        CardView(
          title: "",
          value: "Debug",
          icon: "ladybug.fill",
          description: "Tools for testing.",
          onTap: { showDebugMenu = true }
        )
        CardView(
          title: "",
          value: "Crash",
          icon: "exclamationmark.triangle.fill",
          description: "Test crashing the app.",
          onTap: { let x = ["A"][3] }
        )
#endif
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
      Button("Cancel", role: .cancel) {
        Analytics.track(ClearAllDataCancelEvent())
      }
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
    .sheet(isPresented: $showColorSheet) {
      ColorPickerView()
        .onAppear {
          Analytics.track(ScreenViewColor())
        }
    }
    .sheet(isPresented: $showIconSheet) {
      IconPickerView()
        .onAppear {
          Analytics.track(ScreenViewIcon())
        }
    }
    .sheet(isPresented: $showThemeSheet) {
      ThemePickerView()
        .onAppear {
          Analytics.track(ScreenViewTheme())
        }
    }
#if DEBUG
    .sheet(isPresented: $showDebugMenu) { DebugMenuView() }
#endif
    .onAppear {
      Analytics.track(ScreenViewExtras())
    }
  }

  func confirmClearData() {
    Analytics.track(ClearAllDataEvent())
    if modelContext.deleteAll(FoodEntry.self) {
      Analytics.track(ClearAllDataSuccessEvent())
      onClearAll()
    } else {
      Analytics.track(ClearAllDataFailureEvent())
      showClearFailedAlert = true
    }
  }
}

#Preview {
  ExtrasView(onClearAll: {}, onShowOnboarding: {})
    .background(Color(.systemGroupedBackground))
}
