import SwiftUI

struct DigestView: View {
  @EnvironmentObject var appSettings: AppSettings

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Digest")
              .padding(.top, 48)
              .font(MorselFont.title)
            Text("Week of 17–23 May")
              .font(MorselFont.widgetBody)
              .foregroundStyle(.secondary)
          }

          // Highlights
          VStack(alignment: .leading, spacing: 12) {
            DigestStatRow(icon: "fork.knife", label: "Meals logged", value: "13")
            DigestStatRow(icon: "flame", label: "Cravings resisted", value: "6")
            DigestStatRow(icon: "face.dashed", label: "Cravings given in to", value: "2")
            DigestStatRow(icon: "flame.fill", label: "Streak", value: "3 weeks")
            DigestStatRow(icon: "cup.and.saucer.fill", label: "Most common craving", value: "Biscuits")
          }

          // Encouragement
          VStack(alignment: .leading, spacing: 8) {
            Text("How you did")
              .font(MorselFont.heading)
            Text("You absolutely smashed it this week. Morsel is proud. You even said no to chocolate. *Chocolate!*")
              .font(MorselFont.body)
          }

          // Tip
          VStack(alignment: .leading, spacing: 8) {
            Text("Morsel’s Tip")
              .font(MorselFont.heading)
            Text("Drinking a glass of water can kill a craving before it starts.")
              .font(MorselFont.body)
              .foregroundColor(.secondary)
          }

          // Share or Reflect
          Button(action: {
            // TODO: hook up
          }) {
            Label("Set a goal for next week", systemImage: "target")
              .font(MorselFont.heading)
              .frame(maxWidth: .infinity)
              .padding()
              .background(appSettings.morselColor)
              .foregroundColor(.white)
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          }
        }
        .padding()
      }
    }
  }
}

private struct DigestStatRow: View {
  let icon: String
  let label: String
  let value: String

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .frame(width: 24, height: 24)
        .padding(8)
        .background(.ultraThinMaterial, in: Circle())
      VStack(alignment: .leading) {
        Text(label)
          .font(MorselFont.subheadline)
          .foregroundColor(.secondary)
        Text(value)
          .font(MorselFont.heading)
      }
    }
  }
}
