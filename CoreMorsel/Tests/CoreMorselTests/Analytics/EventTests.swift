@testable import CoreMorsel
import Testing

struct EventTests {
  private struct BasicEvent: Event {
    let name: String
  }

  private struct CustomEvent: Event {
    let name: String
    var parameters: EventParameters { ["foo": "bar"] }
  }

  @Test func defaultParametersAreEmpty() async throws {
    let event = BasicEvent(name: "test.event")
    #expect(event.parameters.isEmpty)
  }

  @Test func customParametersReturnDictionary() async throws {
    let event = CustomEvent(name: "test.event")
    #expect(event.parameters["foo"] == "bar")
  }
}
