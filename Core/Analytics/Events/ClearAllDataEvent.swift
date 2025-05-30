import Foundation

struct ClearAllDataEvent: Event {
  var name: String {
    "clear_all_data"
  }
}

struct ClearAllDataSuccessEvent: Event {
  var name: String {
    "clear_all_data_success"
  }
}

struct ClearAllDataFailureEvent: Event {
  var name: String {
    "clear_all_data_failure"
  }
}

struct ClearAllDataCancelEvent: Event {
  var name: String {
    "clear_all_data_cancel"
  }
}
