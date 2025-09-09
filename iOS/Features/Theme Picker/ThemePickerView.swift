import CoreMorsel
import SwiftUI

struct ThemePickerView: View {
  @EnvironmentObject var appSettings: AppSettings
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    ZStack {
      BackgroundGradientView()
      VStack {
        HStack {
          Spacer()
          ToggleButton(
            isActive: true,
            systemImage: "xmark"
          ) {
            dismiss()
          }
          .padding([.top, .trailing])
        }
        
        Spacer()
        
        VStack(spacing: 24) {
          Text("Appearance")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
          
          VStack(spacing: 16) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
              themeButton(for: theme)
            }
          }
        }
        
        Spacer()
      }
    }
  }
  
  @ViewBuilder
  private func themeButton(for theme: AppTheme) -> some View {
    Button {
      withAnimation(.easeInOut(duration: 0.2)) {
        appSettings.appTheme = theme
      }
    } label: {
      HStack {
        themeIcon(for: theme)
        
        VStack(alignment: .leading, spacing: 4) {
          Text(theme.displayName)
            .font(.headline)
            .foregroundColor(.primary)
          
          Text(themeDescription(for: theme))
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        Spacer()
        
        if appSettings.appTheme == theme {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.blue)
            .font(.title2)
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(.ultraThinMaterial)
          .stroke(appSettings.appTheme == theme ? .blue : .clear, lineWidth: 2)
      )
    }
    .buttonStyle(PlainButtonStyle())
    .padding(.horizontal)
  }
  
  @ViewBuilder
  private func themeIcon(for theme: AppTheme) -> some View {
    Image(systemName: systemImage(for: theme))
      .font(.title2)
      .foregroundColor(.primary)
      .frame(width: 32, height: 32)
  }
  
  private func systemImage(for theme: AppTheme) -> String {
    switch theme {
    case .system:
      return "gear"
    case .light:
      return "sun.max.fill"
    case .dark:
      return "moon.fill"
    }
  }
  
  private func themeDescription(for theme: AppTheme) -> String {
    switch theme {
    case .system:
      return "Matches your device settings"
    case .light:
      return "Light appearance always"
    case .dark:
      return "Dark appearance always"
    }
  }
}

#Preview {
  ThemePickerView()
    .environmentObject(AppSettings.shared)
}