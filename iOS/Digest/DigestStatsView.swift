import SwiftUI

struct DigestStatsView: View {
  let digest: DigestModel

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      DigestStatRow(icon: "fork.knife", label: "Meals logged", value: "\(digest.mealsLogged)")
      DigestStatRow(icon: "flame", label: "Cravings resisted", value: "\(digest.cravingsResisted)")
      DigestStatRow(icon: "face.dashed", label: "Cravings given in to", value: "\(digest.cravingsGivenIn)")
      DigestStatRow(icon: "flame.fill", label: "Streak", value: "\(digest.streakLength) weeks")
      DigestStatRow(icon: "cup.and.saucer.fill", label: "Most common craving", value: digest.mostCommonCraving)
    }
  }
}

