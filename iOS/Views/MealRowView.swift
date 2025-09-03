import CoreMorsel
import SwiftUI
import SwiftData

struct MealRowView: View {
  var entry: FoodEntry
  var onDelete: (() -> Void)? = nil
  var onToggle: (() -> Void)? = nil
  var onRename: ((String) -> Void)? = nil

  @EnvironmentObject private var appSettings: AppSettings
  @State private var showingRename = false
  @State private var newName: String = ""

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: entry.isForMorsel ? "face.smiling.fill" : "person.fill")
        .font(.title3)
        .foregroundStyle(appSettings.morselColor)

      Text(entry.name)
        .font(MorselFont.heading)
        .foregroundColor(.primary)
        .layoutPriority(1)

      Rectangle()
        .foregroundStyle(
          LinearGradient(
            colors: [.clear, .primary.opacity(0.18)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(height: 1)
        .allowsTightening(true)
        .allowsHitTesting(false)

      Text(entry.timestamp, format: .dateTime.hour().minute())
        .font(MorselFont.small)
        .foregroundColor(.secondary)
        .layoutPriority(1)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .contentShape(Rectangle())
    .contextMenu {
      Button {
        onToggle?()
      } label: {
        let label = entry.isForMorsel ? "Change to \"For Me\"" : "Change to \"For Morsel\""
        Label(label, systemImage: "arrow.left.arrow.right")
      }

      Button {
        newName = entry.name
        showingRename = true
      } label: {
        Label("Rename", systemImage: "pencil")
      }

      Button(role: .destructive) {
        onDelete?()
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
    .sheet(isPresented: $showingRename) {
      RenameSheet(
        title: "Rename Item",
        initialText: entry.name,
        onCancel: { showingRename = false },
        onSave: { text in
          onRename?(text)
          showingRename = false
        }
      )
      // Keep the sheet compact; the system will lift it above the keyboard
      .presentationDetents([.fraction(0.22)])
      .presentationDragIndicator(.hidden)
      .interactiveDismissDisabled(false)
    }
  }
}

private struct RenameSheet: View {
  let title: String
  let initialText: String
  let onCancel: () -> Void
  let onSave: (String) -> Void

  @State private var text: String = ""
  @FocusState private var focused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(MorselFont.heading)

      TextField("Name", text: $text)
        .font(MorselFont.body)
        .textFieldStyle(.roundedBorder)
        .focused($focused)
        .submitLabel(.done)
        .onSubmit(saveIfValid)

      HStack(spacing: 16) {
        Button {
          onCancel()
        } label: {
          Image(systemName: "xmark")
        }
        .frame(width: 44, height: 44)
        .background(
          Capsule(style: .continuous)
            .fill(Color.clear)
            .glass(.clear, in: Capsule(style: .continuous))
        )
        .accessibilityLabel("Cancel")

        Spacer(minLength: 0)

        Button {
          saveIfValid()
        } label: {
          Image(systemName: "checkmark")
        }
        .frame(width: 44, height: 44)
        .background(
          Capsule(style: .continuous)
            .fill(Color.clear)
            .glass(.clear, in: Capsule(style: .continuous))
        )
        .accessibilityLabel("Save")
      }
      .padding(.top, 4)
    }
    .padding(16)
    // Auto-focus the text field immediately, ensuring keyboard appears right away
    .onAppear {
      text = initialText
      focused = true
    }
  }

  private func saveIfValid() {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    onSave(trimmed)
  }
}

#Preview {
  MealRowView(entry: FoodEntry(name: "Pasta Bolognese", timestamp: .now)) {
    // delete
  } onToggle: {
    // toggle
  } onRename: { _ in
    // rename
  }
  .padding()
  .environmentObject(AppSettings.shared)
  .modelContainer(for: FoodEntry.self, inMemory: true)
}
