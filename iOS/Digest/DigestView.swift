import CoreMorsel
import SwiftUI

struct DigestView: View {
  @EnvironmentObject var appSettings: AppSettings
  @Environment(\.dismiss) private var dismiss

  var onClose: (() -> Void)? = nil

  @StateObject private var viewModel: DigestViewModel

  init(meals: [Meal], initialOffset: Int? = nil, onClose: (() -> Void)? = nil) {
    self.onClose = onClose
    _viewModel = StateObject(wrappedValue: DigestViewModel(meals: meals, initialOffset: initialOffset))
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        pagesTabView
        bottomControlsView
      }
      .padding(.bottom, geo.safeAreaInsets.bottom - 10)
      .ignoresSafeArea(.all)
    }
  }
}

private extension DigestView {
  var pagesTabView: some View {
    PagesTabView(viewModel: viewModel)
  }

  var bottomControlsView: some View {
    BottomControlsView(
      currentPageIndex: $viewModel.currentPageIndex,
      pageCount: viewModel.availableOffsets.count,
      morselColor: appSettings.morselColor,
      onClose: {
        Haptics.trigger(.selection)
        if let onClose {
          onClose()
        } else {
          dismiss()
        }
      }
    )
  }

  var mask: some View {
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

