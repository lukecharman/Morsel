import Foundation

public struct ClearAllDataEvent: Event {
  public init() {}

  public var name: String {
    "clear_all_data"
  }
}

public struct ClearAllDataSuccessEvent: Event {
  public init() {}

  public var name: String {
    "clear_all_data_success"
  }
}

public struct ClearAllDataFailureEvent: Event {
  public init() {}

  public var name: String {
    "clear_all_data_failure"
  }
}

public struct ClearAllDataCancelEvent: Event {
  public init() {}

  public var name: String {
    "clear_all_data_cancel"
  }
}
