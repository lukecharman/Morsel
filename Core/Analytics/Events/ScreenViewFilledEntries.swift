import Foundation

struct ScreenViewFilledEntries: ScreenViewEvent {
  let screenName = "FilledEntries"
  let count: Int

  var additionalParameters: EventParameters {
    [
      "entryCount": count.description
    ]
  }
}
