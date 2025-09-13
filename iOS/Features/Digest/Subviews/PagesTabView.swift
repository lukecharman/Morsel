import CoreMorsel
import SwiftUI

struct PagesTabView: View {
  @EnvironmentObject var appSettings: AppSettings
  @ObservedObject var viewModel: DigestViewModel

  var body: some View {
    TabView(selection: $viewModel.currentPageIndex) {
      ForEach(viewModel.availableOffsets, id: \.self) { offset in
        let digest = viewModel.digest(at: offset)

        DigestPageView(
          digest: viewModel.digest(at: offset),
          title: digest.title,
          availabilityState: viewModel.digestAvailabilityState(digest),
          blurRadius: viewModel.animatingBlurRadius[viewModel.digestUnlockKey(for: digest)],
          shouldAnimateUnblur: viewModel.shouldAnimateUnblur(for: digest, availabilityState: viewModel.digestAvailabilityState(digest)),
          onWillAnimate: { viewModel.markWillAnimate(for: digest) },
          onTriggerUnblur: { viewModel.triggerUnblurAnimation(for: digest) },
          unlockMessage: viewModel.unlockMessage(for: digest),
          formattedRange: digest.formattedRange
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
