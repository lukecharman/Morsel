@testable import CoreMorsel
import Foundation
import Testing

struct AddContextTests {
  @Test func rawValuesMatchCaseNames() async throws {
    #expect(AddContext.phoneApp.rawValue == "phoneApp")
    #expect(AddContext.phoneWidget.rawValue == "phoneWidget")
    #expect(AddContext.phoneIntent.rawValue == "phoneIntent")
    #expect(AddContext.phoneFromWatch.rawValue == "phoneFromWatch")
    #expect(AddContext.watchApp.rawValue == "watchApp")
    #expect(AddContext.watchFromPhone.rawValue == "watchFromPhone")
  }

  @Test func initialisesFromRawValue() async throws {
    for context in [AddContext.phoneApp, .phoneWidget, .phoneIntent, .phoneFromWatch, .watchApp, .watchFromPhone] {
      #expect(AddContext(rawValue: context.rawValue) == context)
    }
  }
}
