import CoreMorsel
import SwiftUI

struct DigestView: View {
  @EnvironmentObject var appSettings: AppSettings
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel: DigestViewModel

  var onClose: (() -> Void)? = nil

  init(meals: [FoodEntry], initialOffset: Int? = nil, onClose: (() -> Void)? = nil) {
    self.onClose = onClose
    _viewModel = StateObject(wrappedValue: DigestViewModel(meals: meals, initialOffset: initialOffset))
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        if viewModel.meals.isEmpty {
          DigestEmptyStateView()
          VStack {
            Spacer()
            GlassIconButton(systemName: "xmark") {
              onClose?()
            }
            .environmentObject(appSettings)
          }
          .padding(.bottom, 16)
        } else {
          PagesTabView(viewModel: viewModel)
          DigestBottomControlsView(
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
      }
      .padding(.bottom, geo.safeAreaInsets.bottom - 10)
      .ignoresSafeArea(.all)
    }
  }
}

