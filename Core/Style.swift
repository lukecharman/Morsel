import SwiftUI

struct MorselFont {
  static let title = Font.custom("Quicksand-Bold", size: 24, relativeTo: .title)
  static let heading = Font.custom("Quicksand-SemiBold", size: 18, relativeTo: .headline)
  static let body = Font.custom("Quicksand-Regular", size: 15, relativeTo: .body)
  static let subheadline = Font.custom("Quicksand-Regular", size: 13, relativeTo: .subheadline)
  static let caption = Font.custom("Quicksand-Regular", size: 11, relativeTo: .caption)
  static let small = Font.custom("Quicksand-Regular", size: 9, relativeTo: .footnote)

  static let widgetTitle = Font.custom("Quicksand-Bold", size: 16, relativeTo: .title)
  static let widgetBody = Font.custom("Quicksand-Regular", size: 13, relativeTo: .body)
}

extension Font {
  enum morsel {
    static func regular(size: CGFloat) -> Font {
      .custom("Quicksand-Regular", size: size)
    }

    static func medium(size: CGFloat) -> Font {
      .custom("Quicksand-Medium", size: size)
    }

    static func semibold(size: CGFloat) -> Font {
      .custom("Quicksand-SemiBold", size: size)
    }

    static func bold(size: CGFloat) -> Font {
      .custom("Quicksand-Bold", size: size)
    }
  }
}
