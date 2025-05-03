import SwiftUI

struct MorselHeaderCard: View {
  var mealCount: Int

  var body: some View {
    ZStack {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: "fork.knife.circle.fill")
            .font(.system(size: 24))
          Text("Morsel")
            .font(.title2)
            .fontWeight(.bold)
            .fontDesign(.rounded)
        }

        Text(mealCount == 0 ? "No meals yet. Let’s change that!" :
              "You’ve logged \(mealCount) \(mealCount == 1 ? "meal" : "meals") today.")
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(Color.accentColor.opacity(0.1))
          .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
      )
      .padding(.horizontal)
    }
  }
}
