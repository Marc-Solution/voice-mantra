import SwiftUI
import SwiftData

struct CreateListView: View {
    @Environment(\.modelContext) private var modelContext
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
                        
                        // Create new list with SwiftData
                        let newList = AffirmationList(title: trimmed)
                        modelContext.insert(newList)
                        
                        do {
                            try modelContext.save()
                            isPresented = false
                            onCreate?(newList)
                        } catch {
                            print("Failed to save list: \(error)")
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AffirmationList.self, Affirmation.self, configurations: config)
    
    return CreateListView(isPresented: .constant(true))
        .modelContainer(container)
}
