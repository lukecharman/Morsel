@testable import CoreMorsel
import SwiftUI
import Testing

struct ColorUtilitiesTests {
  @Test func darkensColorByPercentage() async throws {
    let original = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6, opacity: 1)
    let darkened = Color.darkened(from: original, percentage: 0.5)

    var oHue: CGFloat = 0, oSat: CGFloat = 0, oBright: CGFloat = 0, oAlpha: CGFloat = 0
    var dHue: CGFloat = 0, dSat: CGFloat = 0, dBright: CGFloat = 0, dAlpha: CGFloat = 0

    UIColor(original).getHue(&oHue, saturation: &oSat, brightness: &oBright, alpha: &oAlpha)
    UIColor(darkened).getHue(&dHue, saturation: &dSat, brightness: &dBright, alpha: &dAlpha)

    #expect(oHue == dHue)
    #expect(oSat == dSat)
    #expect(abs(dBright - (oBright * 0.5)) < 0.0001)
    #expect(oAlpha == dAlpha)
  }
}
