@testable import CoreMorsel
import Foundation
import Testing

struct AnalyticsTests {
  @Test func eventDefaultsToEmptyParameters() async throws {
    struct TestEvent: Event { let name = "test" }
    let event = TestEvent()
    #expect(event.parameters.isEmpty)
  }

  @Test func logForMorselEventHasExpectedParameters() async throws {
    let date = Date(timeIntervalSince1970: 0)
    let event = LogForMorselEvent(craving: "Cake", timestamp: date, context: "app")
    #expect(event.name == "log_for_morsel")
    #expect(event.parameters["name"] == "Cake")
    #expect(event.parameters["timestamp"] == date.isoString)
    #expect(event.parameters["context"] == "app")
  }

  @Test func screenViewEventBuildsName() async throws {
    struct HomeScreen: ScreenViewEvent { let screenName = "Home" }
    let event = HomeScreen()
    #expect(event.name == "ScreenView_Home")
    #expect(event.parameters.isEmpty)
  }

  @Test func screenViewEventIncludesAdditionalParameters() async throws {
    struct StatsScreen: ScreenViewEvent {
      let screenName = "Stats"
      let additionalParameters: EventParameters = ["foo": "bar"]
    }
    let event = StatsScreen()
    #expect(event.parameters["foo"] == "bar")
  }
}
