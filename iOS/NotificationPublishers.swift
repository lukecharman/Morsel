import CoreData
import Foundation
import UIKit

struct NotificationPublishers {
  static var keyboardWillShow: NotificationCenter.Publisher {
    NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
  }

  static var keyboardWillHide: NotificationCenter.Publisher {
    NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
  }

  static var appDidBecomeActive: NotificationCenter.Publisher {
    NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
  }

  static var cloudKitDataChanged: NotificationCenter.Publisher {
    NotificationCenter.default.publisher(for: .cloudKitDataChanged)
  }

  static var persistentCloudKitEventChanged: NotificationCenter.Publisher {
    NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
  }
}
