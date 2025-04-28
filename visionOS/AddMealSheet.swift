import SwiftUI
import SwiftData

struct AddMealSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  @State private var mealName = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    NavigationStack {
      Form {
        TextField("Meal name", text: $mealName)
          .focused($isFocused)
          .submitLabel(.done)
          .onSubmit { save() }
      }
      .navigationTitle("New Meal")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save", action: save)
            .disabled(mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          isFocused = true
        }
      }
    }
  }

  func save() {
    let newEntry = FoodEntry(name: mealName)
    modelContext.insert(newEntry)
    dismiss()
  }
}
