import Foundation

public struct FailedToLoadSwiftDataContainerEvent: Event {
  let error: String

  public init(error: String) {
    self.error = error
  }

  public var name: String {
    "failed_to_load_swiftdata_container"
  }

  public var parameters: EventParameters {
    [
      "error": error
    ]
  }
}
