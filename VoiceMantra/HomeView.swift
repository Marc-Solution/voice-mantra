//
//  HomeView.swift
//  MantraFlow
//
//  Created by Marco Deb on 2025-12-11.
//

import Foundation
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AffirmationList.createdAt, order: .forward) private var lists: [AffirmationList]
    
    @State private var showCreateList = false
    @State private var navigationPath = NavigationPath()
    @State private var pendingNavigationList: AffirmationList? = nil
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Brand background
                Color.brandBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Lists section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Lists")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.brandTextSecondary)
                                .padding(.horizontal, 20)
                            
                            if lists.isEmpty {
                                // Empty state card
                                VStack(spacing: 12) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(.brandAccent.opacity(0.6))
                                    
                                    Text("No lists yet")
                                        .font(.headline)
                                        .foregroundColor(.brandText)
                                    
                                    Text("Create a list to get started")
                                        .font(.subheadline)
                                        .foregroundColor(.brandTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.brandField)
                                )
                                .padding(.horizontal, 16)
                            } else {
                                // List cards
                                VStack(spacing: 10) {
                                    ForEach(lists) { list in
                                        HStack(spacing: 14) {
                                            // Play button
                                            Button(action: {
                                                navigationPath.append(PlayerDestination(list: list))
                                            }) {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(.black)
                                                    .frame(width: 38, height: 38)
                                                    .background(Color.brandAccent)
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            
                                            // NavigationLink for list detail
                                            NavigationLink(value: list) {
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(list.title)
                                                            .font(.body.weight(.medium))
                                                            .foregroundColor(.brandText)
                                                        Text("\(list.affirmations.count) affirmation\(list.affirmations.count == 1 ? "" : "s")")
                                                            .font(.caption)
                                                            .foregroundColor(.brandTextSecondary)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .font(.caption.weight(.semibold))
                                                        .foregroundColor(.brandTextSecondary)
                                                }
                                            }
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.brandField)
                                        )
                                    }
                                    .onDelete(perform: deleteLists)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Quick stats
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Stats")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.brandTextSecondary)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                // Lists stat
                                VStack(spacing: 6) {
                                    Text("\(lists.count)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.brandAccent)
                                    Text("Lists")
                                        .font(.caption)
                                        .foregroundColor(.brandTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.brandField)
                                )
                                
                                // Affirmations stat
                                VStack(spacing: 6) {
                                    Text("\(totalAffirmations)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.brandAccent)
                                    Text("Affirmations")
                                        .font(.caption)
                                        .foregroundColor(.brandTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.brandField)
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("MantraFlow")
            .toolbarBackground(Color.brandBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: AffirmationList.self) { list in
                ListDetailView(list: list)
            }
            .navigationDestination(for: PlayerDestination.self) { destination in
                PlayerView(list: destination.list)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateList = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.bold))
                            Text("Create List")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.brandAccent)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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
