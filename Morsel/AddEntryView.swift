import SwiftUI
import WidgetKit

struct AddEntryView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @FocusState private var isTextFieldFocused: Bool

  @State private var foodName = ""

  var body: some View {
    NavigationView {
      Form {
        TextField("What did you eat?", text: $foodName)
          .focused($isTextFieldFocused)
          .submitLabel(.done)
          .onSubmit {
            saveEntry()
          }
      }
      .navigationTitle("New Entry")
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          isTextFieldFocused = true
        }
      }
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveEntry()
          }
          .disabled(foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  func saveEntry() {
    let newEntry = FoodEntry(name: foodName)
    modelContext.insert(newEntry)
    print("✅ Saved new food entry: \(newEntry.name)")

    dismiss()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      WidgetCenter.shared.reloadAllTimelines()
      print("🔄 Widget reload triggered")
    }
  }
}
