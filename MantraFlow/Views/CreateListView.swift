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
      ZStack {
        // Brand background
        Color.brandBackground.ignoresSafeArea()
        
        VStack(spacing: 24) {
          // Header section
          VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
              .font(.system(size: 50))
              .foregroundColor(.brandAccent)
            
            Text("Create a New List")
              .font(.title2.weight(.semibold))
              .foregroundColor(.brandText)
            
            Text("Give your affirmation list a meaningful name")
              .font(.subheadline)
              .foregroundColor(.brandTextSecondary)
              .multilineTextAlignment(.center)
          }
          .padding(.top, 30)
          
          // Text field
          VStack(alignment: .leading, spacing: 8) {
            Text("List Name")
              .font(.subheadline.weight(.medium))
              .foregroundColor(.brandTextSecondary)
            
            TextField("e.g. Morning Rituals", text: $name)
              .textFieldStyle(.plain)
              .font(.body)
              .foregroundColor(.brandText)
              .padding(16)
              .background(
                RoundedRectangle(cornerRadius: 10)
                  .fill(Color.brandField)
              )
              .disableAutocorrection(true)
          }
          .padding(.horizontal, 24)
          
          // Save button
          Button(action: saveList) {
            Text("Create List")
              .font(.headline.weight(.semibold))
              .foregroundColor(.black)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                     ? Color.brandAccent.opacity(0.4) 
                     : Color.brandAccent)
              )
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          .padding(.horizontal, 24)
          
          Spacer()
        }
      }
      .navigationTitle("New List")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { isPresented = false }
            .foregroundColor(.brandAccent)
        }
      }
    }
  }
  
  private func saveList() {
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
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: AffirmationList.self, Affirmation.self, configurations: config)
  
  return CreateListView(isPresented: .constant(true))
    .modelContainer(container)
}
