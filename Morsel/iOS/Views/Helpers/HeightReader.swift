import SwiftUI

struct HeightReader: View {
  var onChange: (CGFloat) -> Void

  var body: some View {
    GeometryReader { geo in
      Color.clear
        .preference(key: HeightPreferenceKey.self, value: geo.size.height)
    }
    .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
  }
}

struct HeightPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
