import SwiftUI

struct DestinationPicker: View {
  let onSelect: (Bool) -> Void
  let onCancel: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Text("Who was the snack for?")
        .font(MorselFont.title)
        .multilineTextAlignment(.center)

      HStack(spacing: 32) {
        Button {
          onSelect(false)
        } label: {
          VStack {
            Image(systemName: "person.fill")
              .font(.largeTitle)
            Text("Me")
              .font(MorselFont.body)
          }
          .padding()
          .background(Color.accentColor.opacity(0.1))
          .cornerRadius(12)
        }

        Button {
          onSelect(true)
        } label: {
          VStack {
            Image(systemName: "face.smiling.fill")
              .font(.largeTitle)
            Text("Morsel")
              .font(MorselFont.body)
          }
          .padding()
          .background(Color.accentColor.opacity(0.1))
          .cornerRadius(12)
        }
      }

      Button("Cancel") {
        onCancel()
      }
      .foregroundColor(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.4).ignoresSafeArea())
    .transition(.opacity)
    .animation(.easeInOut, value: true)
  }
}
