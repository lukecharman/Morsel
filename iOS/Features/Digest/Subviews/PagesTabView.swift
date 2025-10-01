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
          formattedRange: digest.formattedRange
        )
        .mask(EdgeFadeMask())
        .tag(offset)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))    
  }
}
