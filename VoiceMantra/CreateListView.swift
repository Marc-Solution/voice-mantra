import SwiftUI

struct CreateListView: View {
  @EnvironmentObject var store: AppStore
  @Binding var isPresented: Bool
  @State private var name: String = ""
  
  /// Called when a new list is created, passing the created list
  var onCreate: ((AffirmationList) -> Void)?

  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("List name")) {
          TextField("e.g. Morning Rituals", text: $name)
            .disableAutocorrection(true)
        }
      }
      .navigationTitle("Create List")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { isPresented = false }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            let newList = store.createList(name: trimmed)
            isPresented = false
            // Notify parent about the created list (after dismissal starts)
            onCreate?(newList)
          }
        }
      }
    }
  }
}

