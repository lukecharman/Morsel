@testable import CoreMorsel
import Testing

struct AnalyticsTests {
  private struct DummyEvent: Event {
    let name: String
    var parameters: EventParameters { ["sample": "value"] }
  }

  @Test func setupAndTrack() async throws {
    Analytics.setUp()
    Analytics.track(DummyEvent(name: "test.event"))
  }

  @Test func isoStringProducesISO8601() async throws {
    let date = Date(timeIntervalSince1970: 0)
    #expect(date.isoString == "1970-01-01T00:00:00Z")
  }
}
