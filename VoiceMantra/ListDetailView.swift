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
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            if list.affirmations.isEmpty {
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
                // Affirmations list
                List {
                    ForEach(list.affirmations.sorted(by: { $0.createdAt > $1.createdAt })) { affirmation in
                        Button(action: {
                            affirmationToEdit = affirmation
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    // Display first 20 characters of text property
                                    Text(affirmation.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack(spacing: 8) {
                                        if affirmation.audioFileName != nil {
                                            HStack(spacing: 4) {
                                                Image(systemName: "waveform")
                                                    .font(.caption2)
                                                Text("Audio")
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(.blue)
                                        }
                                        
                                        Text(affirmation.createdAt, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
                    }
                    .onDelete(perform: deleteAffirmations)
                }
                .listStyle(InsetGroupedListStyle())
                .safeAreaInset(edge: .bottom) {
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
        .navigationTitle(list.title)
        .toolbar {
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
    
    // MARK: - Actions
    private func deleteAffirmations(at offsets: IndexSet) {
        let sortedAffirmations = list.affirmations.sorted(by: { $0.createdAt > $1.createdAt })
        for index in offsets {
            let affirmation = sortedAffirmations[index]
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
