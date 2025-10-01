import CoreMorsel
import SwiftUI

struct DigestPageView: View {
  @EnvironmentObject var appSettings: AppSettings

  let digest: DigestModel
  let title: String
  let formattedRange: String

  var body: some View {
    ZStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Spacer().frame(height: 44)
          DigestHeaderView(title: title, dateRange: formattedRange)
          DigestStatsView(digest: digest)
          VStack(alignment: .leading, spacing: 8) {
            Text("How you did")
              .font(MorselFont.heading)
            Text(encouragementText)
              .font(MorselFont.body)
          }
          DigestTipView(tipText: digest.tip.rawValue, accent: appSettings.morselColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
      }
      .ignoresSafeArea()
    }
  }

  private var encouragementText: String {
    // If viewing the current in-progress week, show motivational, forward-looking copy.
    let isCurrentWeek: Bool = {
      let provider = digest.calendarProvider
      let currentStart = provider.startOfDigestWeek(for: Date())
      return provider.isDate(digest.weekStart, inSameDayAs: currentStart)
    }()

    if isCurrentWeek {
      return DigestInProgressCopy.message(for: digest.weekStart)
    }

    // Otherwise, keep the retrospective heuristic for past weeks.
    let meals = digest.mealsLogged
    let resisted = digest.cravingsResisted
    let gaveIn = digest.cravingsGivenIn

    var parts: [String] = []

    if meals > 0 {
      parts.append("You logged \(meals) \(meals == 1 ? "meal" : "meals").")
    }

    if resisted > 0 {
      parts.append("You resisted \(resisted) \(resisted == 1 ? "craving" : "cravings"). Nice work!")
    }

    if gaveIn > 0 {
      parts.append("You gave in \(gaveIn) \(gaveIn == 1 ? "time" : "times"), and that's okay. Progress isn't linear.")
    }

    if parts.isEmpty {
      return "No activity recorded yet. Come back after logging some meals to see your weekly insights."
    } else {
      return parts.joined(separator: " ")
    }
  }
}
