import SwiftUI

public struct MorselFont {
  public static let title = Font.custom("Quicksand-Bold", size: 31, relativeTo: .title)
  public static let heading = Font.custom("Quicksand-SemiBold", size: 19, relativeTo: .headline)
  public static let body = Font.custom("Quicksand-Regular", size: 15, relativeTo: .body)
  public static let subheadline = Font.custom("Quicksand-Regular", size: 13, relativeTo: .subheadline)
  public static let caption = Font.custom("Quicksand-Regular", size: 12, relativeTo: .caption)
  public static let small = Font.custom("Quicksand-Regular", size: 12, relativeTo: .footnote)

  public static let widgetTitle = Font.custom("Quicksand-Bold", size: 16, relativeTo: .title)
  public static let widgetBody = Font.custom("Quicksand-Regular", size: 13, relativeTo: .body)
}

public extension Font {
  enum morsel {
    public static func regular(size: CGFloat) -> Font {
      .custom("Quicksand-Regular", size: size)
    }

    public static func medium(size: CGFloat) -> Font {
      .custom("Quicksand-Medium", size: size)
    }

    public static func semibold(size: CGFloat) -> Font {
      .custom("Quicksand-SemiBold", size: size)
    }

    public static func bold(size: CGFloat) -> Font {
      .custom("Quicksand-Bold", size: size)
    }
  }
}
