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
        .mask(EdgeFadeMask())
        .tag(offset)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .onAppear {
      viewModel.currentPageIndex = viewModel.initialOffset ?? 0
    }
  }
}
