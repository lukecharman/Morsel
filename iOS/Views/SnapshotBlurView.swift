import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct SnapshotBlurView<Content: View>: View {
  let isActive: Bool
  let blurRadius: CGFloat
  @ViewBuilder var content: () -> Content

  @State private var snapshotImage: UIImage?
  private let ciContext = CIContext(options: nil)

  var body: some View {
    GeometryReader { geo in
      let fullSize = geo.size

      ZStack {
        if isActive, let image = snapshotImage {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: fullSize.width, height: fullSize.height)
            .clipped()
            .transition(.blurReplace)
        } else {
          contentContainer(size: fullSize)
            .transition(.blurReplace)
        }
      }
      .frame(width: fullSize.width, height: fullSize.height)
      .contentShape(Rectangle())
      .onChange(of: isActive) { _, active in
        if active {
          Task { await captureAndBlurSnapshot(size: fullSize) }
        } else {
          snapshotImage = nil
        }
      }
      .onChange(of: fullSize) { _, newSize in
        if isActive {
          Task { await captureAndBlurSnapshot(size: newSize) }
        }
      }
      .onAppear {
        // If we appear already active (e.g., during transitions), capture immediately.
        if isActive {
          Task { await captureAndBlurSnapshot(size: fullSize) }
        }
      }
    }
    .ignoresSafeArea() // ensure alignment with backgrounds that ignore safe areas
  }

  @ViewBuilder
  private func contentContainer(size: CGSize) -> some View {
    ZStack {
      content()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(width: size.width, height: size.height)
    .ignoresSafeArea()
  }

  @MainActor
  private func captureAndBlurSnapshot(size: CGSize) async {
    guard size.width > 0, size.height > 0 else { return }

    let renderer = SnapshotRenderer(
      rootView: AnyView(contentContainer(size: size)),
      size: size
    )

    guard let uiImage = renderer.render() else {
      snapshotImage = nil
      return
    }

    snapshotImage = blur(image: uiImage, radius: blurRadius)
  }

  private func blur(image: UIImage, radius: CGFloat) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }
    let inputImage = CIImage(cgImage: cgImage)

    let filter = CIFilter.gaussianBlur()
    filter.inputImage = inputImage
    filter.radius = Float(radius)

    guard let outputImage = filter.outputImage else { return nil }

    // Crop back to original extent to avoid expansion from blur
    let cropped = outputImage.cropped(to: inputImage.extent)

    if let cg = ciContext.createCGImage(cropped, from: inputImage.extent) {
      return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
    return nil
  }
}

// MARK: - UIKit-backed renderer

private final class SnapshotHostingController<Content: View>: UIHostingController<Content> {
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    view.backgroundColor = .clear
  }
}

private struct SnapshotRenderer {
  let rootView: AnyView
  let size: CGSize

  func render() -> UIImage? {
    guard size.width > 0, size.height > 0 else { return nil }

    let controller = SnapshotHostingController(rootView: rootView)
    controller.view.bounds = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .clear

    let format = UIGraphicsImageRendererFormat()
    format.scale = UIScreen.main.scale
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
  }
}
