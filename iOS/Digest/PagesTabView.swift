import CoreMorsel
import SwiftUI

struct PagesTabView: View {
  @EnvironmentObject var appSettings: AppSettings
  @ObservedObject var viewModel: DigestViewModel

  var body: some View {
    TabView(selection: $viewModel.currentPageIndex) {
      ForEach(viewModel.availableOffsets, id: \.self) { offset in
        let digest = viewModel.digest(forOffset: offset)
        let availabilityState = viewModel.digestAvailabilityState(digest)
        let digestKey = viewModel.digestUnlockKey(for: digest)
        let title = viewModel.titleForDigest(digest)

        DigestPageView(
          digest: digest,
          title: title,
          availabilityState: availabilityState,
          blurRadius: viewModel.animatingBlurRadius[digestKey],
          shouldAnimateUnblur: viewModel.shouldAnimateUnblur(for: digest, availabilityState: availabilityState),
          onWillAnimate: { viewModel.markWillAnimate(for: digest) },
          onTriggerUnblur: { viewModel.triggerUnblurAnimation(for: digest) },
          unlockMessage: viewModel.unlockMessage(for: digest),
          formattedRange: viewModel.formattedRange(for: digest)
        )
        .mask { mask }
        .tag(offset)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
  }

  // Reuse the same mask shape as parent
  private var mask: some View {
    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: .clear, location: 0.0),
        .init(color: .black, location: 0.03),
        .init(color: .black, location: 0.92),
        .init(color: .clear, location: 0.95),
        .init(color: .clear, location: 1.0)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )
    .blur(radius: 22)
  }
}

