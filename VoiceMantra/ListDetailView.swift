import SwiftUI

struct ListDetailView: View {
  @EnvironmentObject var store: AppStore
  @Environment(\.dismiss) private var dismiss
  
  let listId: UUID
  let listName: String
  
  @State private var showCreateAffirmation = false
  @State private var showRenameAlert = false
  @State private var showDeleteAlert = false
  @State private var newListName = ""
  
  // Computed property to always get the latest list from the store
  private var currentList: AffirmationList? {
    store.lists.first(where: { $0.id == listId })
  }
  
  // Get the current name from store (for live updates after rename)
  private var displayName: String {
    currentList?.name ?? listName
  }
  
  private var affirmations: [Affirmation] {
    currentList?.affirmations ?? []
  }

  var body: some View {
    ZStack {
      // Background
      Color(UIColor.systemGroupedBackground)
        .ignoresSafeArea()
      
      if affirmations.isEmpty {
        // Empty state placeholder
        VStack(spacing: 16) {
          Image(systemName: "waveform.circle")
            .font(.system(size: 60))
            .foregroundColor(.secondary.opacity(0.5))
          
          Text("No affirmations yet")
            .font(.headline)
            .foregroundColor(.secondary)
          
          Text("Tap '+' to record your first one")
            .font(.subheadline)
            .foregroundColor(.secondary.opacity(0.8))
        }
        .padding()
      } else {
        // Affirmations list with card styling and swipe-to-delete
        List {
          ForEach(affirmations) { aff in
            NavigationLink(destination: makeEditorView(for: aff)) {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(aff.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                  
                  if let d = aff.durationSeconds {
                    HStack(spacing: 4) {
                      Image(systemName: "waveform")
                        .font(.caption2)
                      Text("\(d) sec")
                        .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                  }
                }
                
                Spacer()
              }
            }
            .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
          }
          .onDelete(perform: deleteAffirmations)
        }
        .listStyle(InsetGroupedListStyle())
        .safeAreaInset(edge: .bottom) {
          // Space for FAB
          Color.clear.frame(height: 80)
        }
      }
      
      // Floating Action Button
      VStack {
        Spacer()
        HStack {
          Spacer()
          Button(action: {
            showCreateAffirmation = true
          }) {
            Image(systemName: "plus")
              .font(.system(size: 24, weight: .semibold))
              .foregroundColor(.white)
              .frame(width: 60, height: 60)
              .background(
                LinearGradient(
                  gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .clipShape(Circle())
              .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
          }
          .padding(.trailing, 20)
          .padding(.bottom, 20)
        }
      }
    }
    .navigationTitle(displayName)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button(action: {
            newListName = displayName
            showRenameAlert = true
          }) {
            Label("Rename List", systemImage: "pencil")
          }
          
          Button(role: .destructive, action: {
            showDeleteAlert = true
          }) {
            Label("Delete List", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 17))
        }
      }
    }
    .alert("Rename List", isPresented: $showRenameAlert) {
      TextField("List name", text: $newListName)
      Button("Cancel", role: .cancel) { }
      Button("Save") {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          store.renameList(id: listId, newName: trimmed)
        }
      }
    } message: {
      Text("Enter a new name for this list.")
    }
    .alert("Delete \(displayName)?", isPresented: $showDeleteAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Delete", role: .destructive) {
        store.deleteList(id: listId)
        dismiss()
      }
    } message: {
      Text("This will also delete all recorded affirmations inside. This action cannot be undone.")
    }
    .sheet(isPresented: $showCreateAffirmation) {
      AffirmationEditorView(
        vm: AffirmationEditorViewModel(),
        saveAction: { transcript, audioURL, duration in
          // Generate title from first 20 characters of transcript
          let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
          let title = String(trimmed.prefix(20))
          let finalTitle = title.isEmpty ? "Untitled" : (trimmed.count > 20 ? title + "..." : title)
          
          // Create and save via store with this list's ID
          let created = store.createAffirmation(title: finalTitle, listId: listId)
          
          // Update created fields
          var updated = created
          updated.transcript = transcript
          updated.durationSeconds = audioURL != nil ? Int(duration) : nil
          
          // Persist to this specific list
          store.saveAffirmation(updated, toListId: listId)
        }
      )
      .environmentObject(store)
    }
  }
  
  // MARK: - Actions
  private func deleteAffirmations(at offsets: IndexSet) {
    for index in offsets {
      let affirmation = affirmations[index]
      store.deleteAffirmation(id: affirmation.id, fromListId: listId)
    }
  }
  
  // MARK: - Editor View Factory
  /// Creates an editor view for an existing affirmation with proper save action
  private func makeEditorView(for affirmation: Affirmation) -> some View {
    AffirmationEditorView(
      vm: AffirmationEditorViewModel(transcript: affirmation.transcript ?? ""),
      saveAction: { transcript, audioURL, duration in
        // Generate updated title from first 20 characters of transcript
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = String(trimmed.prefix(20))
        let finalTitle = title.isEmpty ? "Untitled" : (trimmed.count > 20 ? title + "..." : title)
        
        // Create updated affirmation with same ID
        var updated = affirmation
        updated.title = finalTitle
        updated.transcript = transcript
        updated.durationSeconds = audioURL != nil ? Int(duration) : affirmation.durationSeconds
        
        // Save to store (this will update the existing affirmation)
        store.saveAffirmation(updated, toListId: listId)
      }
    )
    .environmentObject(store)
  }
}

// Convenience initializer to maintain backward compatibility
extension ListDetailView {
  init(list: AffirmationList) {
    self.listId = list.id
    self.listName = list.name
  }
}


