import Foundation

struct ScreenViewFilledEntries: ScreenViewEvent {
  let screenName = "FilledEntries"
  let count: Int

  var additionalParameters: EventParameters {
    [
      "entry_count": count.description
    ]
  }
}
