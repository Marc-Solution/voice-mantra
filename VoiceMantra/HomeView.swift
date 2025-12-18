
//  HomeView.swift
//  Appformations
//
//  Created by Marco Deb on 2025-12-11.
//

import Foundation
import SwiftUI

struct HomeView: View {
  @EnvironmentObject var store: AppStore

  @State private var showCreateList = false
  @State private var showCreateAffirmation = false
  @State private var selectedListForAdd: UUID? = nil
  
  // Navigation path for programmatic navigation
  @State private var navigationPath = NavigationPath()
  
  // Temporarily store the newly created list to navigate after sheet dismisses
  @State private var pendingNavigationList: AffirmationList? = nil

  var body: some View {
    NavigationStack(path: $navigationPath) {
      List {
        // Lists section
        Section(header: Text("Lists")) {
          if store.lists.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              Text("No lists yet")
                .foregroundColor(.secondary)
              Text("Create a list or record an affirmation to get started.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
          } else {
            ForEach(store.lists) { list in
              HStack(spacing: 12) {
                // Play button on the left - navigates to PlayerView
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
                
                // NavigationLink for the rest of the card - navigates to ListDetailView
                NavigationLink(value: list) {
                  VStack(alignment: .leading, spacing: 2) {
                    Text(list.name)
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
          }
        }

        // Drafts section
        if !store.drafts.isEmpty {
          Section(header: Text("Drafts")) {
            ForEach(store.drafts) { draft in
              NavigationLink(destination: AffirmationEditorView(vm: AffirmationEditorViewModel(transcript: draft.transcript ?? ""))) {
                VStack(alignment: .leading) {
                  Text(draft.title.isEmpty ? "Untitled" : draft.title)
                  Text(draft.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
              }
            }
          }
        }

        // Quick stats
        Section(header: Text("Stats")) {
          HStack {
            VStack(alignment: .leading) {
              Text("Lists")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(store.lists.count)")
                .font(.headline)
            }
            Spacer()
            VStack(alignment: .leading) {
              Text("Drafts")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(store.drafts.count)")
                .font(.headline)
            }
          }
        }
      }
      .listStyle(InsetGroupedListStyle())
      .navigationTitle("AppFirmations")
      .navigationDestination(for: AffirmationList.self) { list in
        ListDetailView(list: list)
      }
      .navigationDestination(for: PlayerDestination.self) { destination in
        PlayerView(destination: destination)
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Create List") { showCreateList = true }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack {
            Button(action: { showCreateAffirmation = true }) {
              Image(systemName: "mic.fill")
            }
            Button(action: { /* future profile/settings */ }) {
              Image(systemName: "person.crop.circle")
            }
          }
        }
      }
      .sheet(isPresented: $showCreateList, onDismiss: {
        // After sheet dismisses, navigate to the new list if one was created
        if let newList = pendingNavigationList {
          // Small delay to ensure sheet is fully dismissed before navigation
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            navigationPath.append(newList)
            pendingNavigationList = nil
          }
        }
      }) {
        CreateListView(isPresented: $showCreateList, onCreate: { createdList in
          // Store the created list for navigation after dismissal
          pendingNavigationList = createdList
        })
        .environmentObject(store)
      }
      .sheet(isPresented: $showCreateAffirmation) {
        // If selectedListForAdd is set, pass it to the create view so the editor knows the parent
        AffirmationEditorView(vm: AffirmationEditorViewModel(), saveAction: { transcript, audioURL, duration in
          // Generate title from first 20 characters of transcript
          let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
          let title = String(trimmed.prefix(20))
          let finalTitle = title.isEmpty ? "Untitled" : (trimmed.count > 20 ? title + "..." : title)
          // create and save via store
          let created = store.createAffirmation(title: finalTitle, listId: selectedListForAdd)
          // update created fields
          var updated = created
          updated.transcript = transcript
          updated.durationSeconds = audioURL != nil ? Int(duration) : nil
          // persist (naive)
          store.saveAffirmation(updated, toListId: selectedListForAdd)
          // clear parent pointer after save
          selectedListForAdd = nil
        })
        .environmentObject(store)
      }
    }
  }
}

// Optional preview
struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
      .environmentObject(AppStore())
  }
}
