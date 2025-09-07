import CoreMorsel
import SwiftUI
import UserNotifications

// MARK: - View

struct DigestView: View {
  @EnvironmentObject var appSettings: AppSettings
  @Environment(\.dismiss) private var dismiss

  let meals: [Meal]
  var initialOffset: Int? = nil
  var onClose: (() -> Void)? = nil

  @StateObject private var viewModel: DigestViewModel

  init(meals: [Meal], initialOffset: Int? = nil, onClose: (() -> Void)? = nil) {
    self.meals = meals
    self.initialOffset = initialOffset
    self.onClose = onClose
    _viewModel = StateObject(wrappedValue: DigestViewModel(meals: meals, initialOffset: initialOffset))
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        VStack(spacing: 0) {
          TabView(selection: $viewModel.currentPageIndex) {
            ForEach(viewModel.availableOffsets, id: \.self) { offset in
              let digest = viewModel.digest(forOffset: offset)
              let availabilityState = viewModel.digestAvailabilityState(digest)
              let digestKey = viewModel.digestUnlockKey(for: digest)
              let title = viewModel.titleForDigest(digest)

              ZStack {
                ScrollView {
                  VStack(alignment: .leading, spacing: 24) {
                    Spacer().frame(height: 44)

                    VStack(alignment: .leading, spacing: 8) {
                      Text(title)
                        .padding(.top, 16)
                        .font(MorselFont.title)

                      Text(viewModel.formattedRange(for: digest))
                        .font(MorselFont.body)
                        .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                      DigestStatRow(icon: "fork.knife", label: "Meals logged", value: "\(digest.mealsLogged)")
                      DigestStatRow(icon: "flame", label: "Cravings resisted", value: "\(digest.cravingsResisted)")
                      DigestStatRow(icon: "face.dashed", label: "Cravings given in to", value: "\(digest.cravingsGivenIn)")
                      DigestStatRow(icon: "flame.fill", label: "Streak", value: "\(digest.streakLength) weeks")
                      DigestStatRow(icon: "cup.and.saucer.fill", label: "Most common craving", value: digest.mostCommonCraving)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                      Text("How you did")
                        .font(MorselFont.heading)
                      Text(viewModel.encouragement(for: digest))
                        .font(MorselFont.body)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                      Text("Morsel's Tip")
                        .font(MorselFont.heading)

                      HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(digest.tip.rawValue)
                          .font(MorselFont.body)

                        Spacer(minLength: 8)

                        Button(action: {
                          Haptics.trigger(.selection)
                        }) {
                          Image(systemName: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(appSettings.morselColor)
                            .frame(width: 32, height: 32)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Share tip")
                      }
                    }
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding()
                  .blur(radius: availabilityState == .locked ? 8 : (viewModel.animatingBlurRadius[digestKey] ?? (availabilityState == .unlockable ? 8 : 0)))
                  .allowsHitTesting(availabilityState != .locked)
                  .accessibilityHidden(availabilityState == .locked)
                }
                .disabled(availabilityState == .locked)
                .ignoresSafeArea()
                .mask { mask }
                .onAppear {
                  let shouldAnimate = viewModel.shouldAnimateUnblur(for: digest, availabilityState: availabilityState)
                  if shouldAnimate {
                    viewModel.markWillAnimate(for: digest)
                    viewModel.triggerUnblurAnimation(for: digest)
                  }
                }

                if availabilityState == .locked {
                  VStack(spacing: 12) {
                    Text("This week isn't finished yet!")
                      .font(MorselFont.heading)
                    Text(viewModel.unlockMessage(for: digest))
                      .font(MorselFont.body)
                      .multilineTextAlignment(.center)
                  }
                  .padding()
                  .frame(maxWidth: .infinity)
                  .background(.ultraThinMaterial)
                  .cornerRadius(12)
                  .padding()
                }
              }
              .tag(offset)
            }
          }
          .tabViewStyle(.page(indexDisplayMode: .never))
          .onAppear {
            // Set the initial page index based on the provided initialOffset
            viewModel.currentPageIndex = viewModel.initialOffset ?? 0
          }
        }

        // Bottom controls
        VStack {
          Spacer()
          HStack(spacing: 24) {
            Button(action: {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                viewModel.currentPageIndex = min(viewModel.currentPageIndex + 1, viewModel.availableOffsets.count - 1)
              }
            }) {
              Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .opacity(viewModel.currentPageIndex < viewModel.availableOffsets.count - 1 ? 1 : 0.4)
            .disabled(viewModel.currentPageIndex >= viewModel.availableOffsets.count - 1)
            .accessibilityLabel("Previous period")

            Button(action: {
              Haptics.trigger(.selection)
              if let onClose {
                onClose()
              } else {
                dismiss()
              }
            }) {
              Image(systemName: "xmark")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close digest")

            Button(action: {
              withAnimation(.interactiveSpring(response: 0.85, dampingFraction: 0.68)) {
                viewModel.currentPageIndex = max(viewModel.currentPageIndex - 1, 0)
              }
            }) {
              Image(systemName: "chevron.right")
                .font(.title3)
                .foregroundStyle(appSettings.morselColor)
                .frame(width: 44, height: 44)
            }
            .opacity(viewModel.currentPageIndex > 0 ? 1 : 0.4)
            .disabled(viewModel.currentPageIndex == 0)
            .accessibilityLabel("Next period")
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            Capsule(style: .continuous)
              .fill(Color.clear)
              .glassEffect(.clear, in: Capsule(style: .continuous))
          )
          .padding(.bottom, geo.safeAreaInsets.bottom - 10)
        }
      }
      .ignoresSafeArea(.all)
    }
  }

  // MARK: - Mask

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
