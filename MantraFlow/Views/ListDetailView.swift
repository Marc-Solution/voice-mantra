import SwiftUI
import SwiftData

struct ListDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  
  @Bindable var list: AffirmationList
  
  @State private var showCreateAffirmation = false
  @State private var showRenameAlert = false
  @State private var showDeleteAlert = false
  @State private var newListName = ""
  @State private var affirmationToEdit: Affirmation? = nil
  
  var body: some View {
    ZStack {
      // Brand background
      Color.brandBackground.ignoresSafeArea()
      
      VStack(spacing: 0) {
        // MARK: - Header with Title and Play Button
        HStack(spacing: 16) {
          // List Title
          Text(list.title)
            .font(.title2.weight(.bold))
            .foregroundColor(.brandText)
          
          Spacer()
          
          // Play All Button - only shows when there are playable affirmations
          if hasPlayableAffirmations {
            NavigationLink(value: PlayerDestination(list: list)) {
              Image(systemName: "play.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.brandAccent)
                .shadow(color: Color.brandAccent.opacity(0.3), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .transition(.opacity.combined(with: .scale))
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .animation(.easeInOut(duration: 0.4), value: hasPlayableAffirmations)
        
        // MARK: - Content Area
        if list.affirmations.isEmpty {
          // Empty state placeholder
          VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "waveform.circle")
              .font(.system(size: 60))
              .foregroundColor(.brandAccent.opacity(0.5))
            
            Text("No affirmations yet")
              .font(.headline)
              .foregroundColor(.brandText)
            
            Text("Tap '+' to record your first one")
              .font(.subheadline)
              .foregroundColor(.brandTextSecondary)
            
            Spacer()
          }
          .padding()
        } else {
          // Affirmations list with swipe-to-delete and drag-to-reorder
          List {
            ForEach(sortedAffirmations) { affirmation in
              HStack(spacing: 14) {
                // Main content button
                Button(action: {
                  affirmationToEdit = affirmation
                }) {
                  HStack(spacing: 14) {
                    // Status Icon - Accent for complete, dimmed for draft
                    ZStack {
                      Circle()
                        .fill(affirmation.isDraft ? Color.brandField : Color.brandAccent.opacity(0.2))
                        .frame(width: 42, height: 42)
                      
                      Image(systemName: affirmation.isDraft ? "mic.badge.plus" : "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(affirmation.isDraft ? .brandTextSecondary : .brandAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                      // Display first 20 characters of text property
                      Text(affirmation.displayName)
                        .font(.body.weight(.medium))
                        .foregroundColor(.brandText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                      
                      HStack(spacing: 8) {
                        // Status badge
                        HStack(spacing: 4) {
                          Image(systemName: affirmation.isDraft ? "doc.text" : "checkmark.circle.fill")
                            .font(.caption2)
                          Text(affirmation.isDraft ? "Draft" : "Complete")
                            .font(.caption2)
                        }
                        .foregroundColor(affirmation.isDraft ? .brandTextSecondary : .brandAccent)
                        
                        Text("•")
                          .font(.caption2)
                          .foregroundColor(.brandTextSecondary)
                        
                        Text(affirmation.createdAt, style: .date)
                          .font(.caption2)
                          .foregroundColor(.brandTextSecondary)
                      }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                      .font(.caption.weight(.semibold))
                      .foregroundColor(.brandTextSecondary)
                  }
                  .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Mute/Unmute button
                Button(action: {
                  withAnimation(.easeInOut(duration: 0.2)) {
                    affirmation.isMuted.toggle()
                  }
                  try? modelContext.save()
                }) {
                  Image(systemName: affirmation.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(affirmation.isMuted ? .brandTextSecondary : .brandAccent)
                    .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
              }
              .opacity(affirmation.isMuted ? 0.5 : 1.0)
              .listRowBackground(Color.brandField)
              .listRowSeparator(.hidden)
              .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            }
            .onMove(perform: moveAffirmations)
            .onDelete(perform: deleteAffirmations)
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .background(Color.brandBackground)
          .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80)  // Space for FAB
          }
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
              .font(.system(size: 24, weight: .bold))
              .foregroundColor(.black)
              .frame(width: 60, height: 60)
              .background(Color.brandAccent)
              .clipShape(Circle())
              .shadow(color: Color.brandAccent.opacity(0.4), radius: 8, x: 0, y: 4)
          }
          .padding(.trailing, 20)
          .padding(.bottom, 20)
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(Color.brandBackground, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbar {
      // Edit button for drag-to-reorder
      ToolbarItem(placement: .navigationBarTrailing) {
        EditButton()
          .foregroundColor(.brandAccent)
      }
      
      // Three-dots menu
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button(action: {
            newListName = list.title
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
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(.brandAccent)
        }
      }
    }
    .alert("Rename List", isPresented: $showRenameAlert) {
      TextField("List name", text: $newListName)
      Button("Cancel", role: .cancel) { }
      Button("Save") {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          list.title = trimmed
        }
      }
    } message: {
      Text("Enter a new name for this list.")
    }
    .alert("Delete \(list.title)?", isPresented: $showDeleteAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Delete", role: .destructive) {
        // Delete audio files first
        for affirmation in list.affirmations {
          deleteAudioFile(for: affirmation)
        }
        modelContext.delete(list)
        // Explicitly save before dismissing to persist deletion
        try? modelContext.save()
        dismiss()
      }
    } message: {
      Text("This will also delete all recorded affirmations inside. This action cannot be undone.")
    }
    .sheet(isPresented: $showCreateAffirmation) {
      AffirmationEditorView(list: list)
    }
    .sheet(item: $affirmationToEdit) { affirmation in
      AffirmationEditorView(list: list, existingAffirmation: affirmation)
    }
  }
  
  // MARK: - Computed Properties
  
  /// Returns affirmations sorted by sortOrder (with createdAt as tiebreaker for existing records)
  private var sortedAffirmations: [Affirmation] {
    list.affirmations.sorted { first, second in
      if first.sortOrder != second.sortOrder {
        return first.sortOrder < second.sortOrder
      }
      // If sortOrder is the same (e.g., both 0 for existing records), use createdAt
      return first.createdAt < second.createdAt
    }
  }
  
  /// Returns true if there are any affirmations with recorded audio that are not muted
  private var hasPlayableAffirmations: Bool {
    list.affirmations.contains { !$0.isDraft && !$0.isMuted }
  }
  
  // MARK: - Actions
  
  /// Handles drag-and-drop reordering of affirmations
  private func moveAffirmations(from source: IndexSet, to destination: Int) {
    var reordered = sortedAffirmations
    
    // Move items in the array
    reordered.move(fromOffsets: source, toOffset: destination)
    
    // Update sortOrder for all affirmations to reflect new order
    for (index, affirmation) in reordered.enumerated() {
      affirmation.sortOrder = index
    }
    
    // Persist changes
    try? modelContext.save()
  }
  
  private func deleteAffirmations(at offsets: IndexSet) {
    let currentSorted = sortedAffirmations
    for index in offsets {
      let affirmation = currentSorted[index]
      deleteAudioFile(for: affirmation)
      modelContext.delete(affirmation)
    }
    // Explicitly save to persist deletion
    try? modelContext.save()
  }
  
  private func deleteAudioFile(for affirmation: Affirmation) {
    guard let fileName = affirmation.audioFileName else { return }
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsPath.appendingPathComponent(fileName)
    try? FileManager.default.removeItem(at: fileURL)
  }
}

// Preview
#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: AffirmationList.self, Affirmation.self, configurations: config)
  let sampleList = AffirmationList(title: "Morning Affirmations")
  
  return NavigationStack {
    ListDetailView(list: sampleList)
  }
  .modelContainer(container)
}
