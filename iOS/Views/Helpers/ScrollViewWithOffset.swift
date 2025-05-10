import SwiftUI

enum ScrollOffsetNamespace {
  static let namespace = "scrollView"
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGPoint = .zero
  static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

struct ScrollViewOffsetTracker: View {
  var body: some View {
    GeometryReader { geo in
      Color.clear
        .preference(
          key: ScrollOffsetPreferenceKey.self,
          value: geo
            .frame(in: .named(ScrollOffsetNamespace.namespace))
            .origin
        )
    }
    .frame(height: 0)
  }
}

private extension ScrollView {
  func withOffsetTracking(
    action: @escaping (_ offset: CGPoint) -> Void
  ) -> some View {
    self.coordinateSpace(name: ScrollOffsetNamespace.namespace)
      .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
  }
}

struct ScrollViewWithOffset<Content: View>: View {
  public init(
    _ axes: Axis.Set = .vertical,
    showsIndicators: Bool = true,
    onScroll: ScrollAction? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.axes = axes
    self.showsIndicators = showsIndicators
    self.onScroll = onScroll ?? { _ in }
    self.content = content
  }

  private let axes: Axis.Set
  private let showsIndicators: Bool
  private let onScroll: ScrollAction
  private let content: () -> Content

  public typealias ScrollAction = (_ offset: CGPoint) -> Void

  public var body: some View {
    ScrollView(axes, showsIndicators: showsIndicators) {
      ZStack(alignment: .top) {
        ScrollViewOffsetTracker()
        content()
      }
    }.withOffsetTracking(action: onScroll)
  }
}
