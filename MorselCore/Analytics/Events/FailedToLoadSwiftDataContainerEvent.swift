import Foundation

struct FailedToLoadSwiftDataContainerEvent: Event {
  let error: String

  var name: String {
    "failed_to_load_swiftdata_container"
  }

  var parameters: EventParameters {
    [
      "error": error
    ]
  }
}
