#if DEBUG
import SwiftUI
import CoreMorsel

struct DebugMenuView: View {
  @State private var showStudio = false
  private let notificationsManager = NotificationsManager()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          CardView(
            title: "",
            value: "Schedule Digest",
            icon: "timer",
            description: "Lock current digest and notify in 30 seconds.",
            onTap: { notificationsManager.scheduleDebugDigest() }
          )
          CardView(
            title: "",
            value: "Morsel Studio",
            icon: "paintpalette",
            description: "Debug Morsel animations.",
            onTap: { showStudio = true }
          )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
      }
      .navigationTitle("Debug")
      .sheet(isPresented: $showStudio) { MorselStudio() }
    }
  }
}
#endif
