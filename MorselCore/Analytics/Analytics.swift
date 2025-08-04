import Foundation
import TelemetryDeck

struct Analytics {
  static func setUp() {
    let config = TelemetryDeck.Config(appID: "0450C03B-3699-46A4-A99C-FB9F78C887E2")
    config.defaultSignalPrefix = "morsel."
    config.defaultParameterPrefix = "morsel."

    TelemetryDeck.initialize(config: config)
  }

  static func track(_ event: Event) {
    TelemetryDeck.signal(event.name, parameters: event.parameters)
  }
}

extension Date {
  var isoString: String {
    ISO8601DateFormatter().string(from: self)
  }
}
