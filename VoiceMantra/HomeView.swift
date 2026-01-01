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
  @State private var showSettings = false
  @State private var navigationPath = NavigationPath()
  @State private var pendingNavigationList: AffirmationList? = nil
    
    /// Streak manager for stats display
    @StateObject private var streakManager = StreakManager.shared

  var body: some View {
    NavigationStack(path: $navigationPath) {
            ZStack {
                // Brand background
                Color.brandBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Pinned Stats Row (Top)
                    statsRow
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                        .background(
                            Color.brandBackground
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                    
                    // MARK: - Scrollable Lists Section
                    ScrollView {
                        VStack(spacing: 16) {
                            // Section header
                            HStack {
                                Text("Your Lists")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.brandTextSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            
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
                                        listRow(for: list)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
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
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.brandAccent)
            }
        }
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
      .sheet(isPresented: $showSettings) {
          SettingsView()
      }
            .onAppear {
                // Check and reset streak if a full calendar day was missed
                // This ensures the UI updates immediately when the app opens or stays open across midnight
                streakManager.checkAndResetStreak()
            }
        }
    }
    
    // MARK: - Stats Row (Compact Pills)
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            // Streak Pill
            HStack(spacing: 8) {
                // Flame with glow effect when active
                ZStack {
                    if streakManager.currentStreak > 0 {
                        // Glow effect
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.brandAccent)
                            .blur(radius: 6)
                            .opacity(0.7)
                    }
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(streakManager.currentStreak > 0 ? .brandAccent : .brandTextSecondary)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(streakManager.currentStreak) Days")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(streakManager.currentStreak > 0 ? .brandText : .brandTextSecondary)
                    
                    Text("Streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.brandTextSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.brandField)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                streakManager.currentStreak > 0 
                                    ? Color.brandAccent.opacity(0.3) 
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            
            // Total Time Pill
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandAccent)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(streakManager.formattedTotalTime)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.brandText)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text("Total")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.brandTextSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.brandField)
            )
            
            Spacer()
        }
    }
    
    // MARK: - List Row
    
    private func listRow(for list: AffirmationList) -> some View {
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
            .buttonStyle(PlainButtonStyle())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.brandField)
        )
    }
    
    // Note: List deletion is handled via the "..." menu in ListDetailView,
    // which includes proper confirmation dialogs and audio file cleanup.
}

// Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AffirmationList.self, Affirmation.self, configurations: config)
    
    return HomeView()
        .modelContainer(container)
}
