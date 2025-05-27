import SwiftUI

struct IconPickerView: View {
  @Environment(\.dismiss) var dismiss

  let icons = ["Yellow", "Blue", "Red", "Green", "Pink", "Orange", "Purple", "Mint"]
  let columns = [GridItem(.flexible()), GridItem(.flexible())]

  var body: some View {
    ZStack(alignment: .topTrailing) {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(icons, id: \.self) { icon in
            Button(action: {
              changeAppIcon(to: icon)
            }) {
              VStack {
                Image(uiImage: UIImage(named: icon) ?? UIImage())
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 80, height: 80)
                  .cornerRadius(16)
                Text(icon)
                  .font(.caption)
                  .foregroundColor(.primary)
              }
            }
          }
        }
        .padding()
      }

      ToggleButton(
        isActive: true,
        systemImage: "xmark",
        action: { dismiss() }
      )
      .padding()
    }
  }

  func changeAppIcon(to iconName: String) {
    UIApplication.shared.setAlternateIconName(iconName) { error in
      if let error = error {
        print("Error changing icon: \(error.localizedDescription)")
      }
    }
  }
}
