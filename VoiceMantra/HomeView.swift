//
//  HomeView.swift
//  VoiceMantra
//
//  Created by Marco Deb on 2025-12-11.
//

import Foundation
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AffirmationList.createdAt, order: .reverse) private var lists: [AffirmationList]
    
    @State private var showCreateList = false
    @State private var navigationPath = NavigationPath()
    @State private var pendingNavigationList: AffirmationList? = nil
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                // Lists section
                Section(header: Text("Lists")) {
                    if lists.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No lists yet")
                                .foregroundColor(.secondary)
                            Text("Create a list to get started.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else {
                        ForEach(lists) { list in
                            HStack(spacing: 12) {
                                // Play button - navigates to PlayerView
                                Button(action: {
                                    navigationPath.append(PlayerDestination(list: list))
                                }) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                // NavigationLink for list detail
                                NavigationLink(value: list) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(list.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        Text("\(list.affirmations.count) affirmation\(list.affirmations.count == 1 ? "" : "s")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteLists)
                    }
                }
                
                // Quick stats
                Section(header: Text("Stats")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Lists")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(lists.count)")
                                .font(.headline)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Affirmations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totalAffirmations)")
                                .font(.headline)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("VoiceMantra")
            .navigationDestination(for: AffirmationList.self) { list in
                ListDetailView(list: list)
            }
            .navigationDestination(for: PlayerDestination.self) { destination in
                PlayerView(list: destination.list)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateList = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateList, onDismiss: {
                if let newList = pendingNavigationList {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigationPath.append(newList)
                        pendingNavigationList = nil
                    }
                }
            }) {
                CreateListView(isPresented: $showCreateList) { createdList in
                    pendingNavigationList = createdList
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalAffirmations: Int {
        lists.reduce(0) { $0 + $1.affirmations.count }
    }
    
    // MARK: - Actions
    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            let list = lists[index]
            // Delete associated audio files
            for affirmation in list.affirmations {
                deleteAudioFile(for: affirmation)
            }
            modelContext.delete(list)
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
    
    return HomeView()
        .modelContainer(container)
}
