import SafariServices
import SwiftUI

struct FeedbackView: UIViewControllerRepresentable {
  let url: URL = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSe1orbaEkwXlO0QAT_2lggdXmlNOD9cnGst9Dr1Ydx4p8Rq3w/viewform")!

  func makeUIViewController(context: Context) -> SFSafariViewController {
    SFSafariViewController(url: url)
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
