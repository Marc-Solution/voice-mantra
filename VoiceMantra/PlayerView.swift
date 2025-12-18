//
//  PlayerView.swift
//  Appformations
//
//  Created for Appformations
//

import SwiftUI

/// Wrapper type for programmatic navigation to PlayerView
/// This distinguishes player navigation from list detail navigation
struct PlayerDestination: Hashable {
  let list: AffirmationList
}

struct PlayerView: View {
  @EnvironmentObject var store: AppStore
  @Environment(\.dismiss) private var dismiss
  
  let list: AffirmationList
  
  // Get the latest list data from store
  private var currentList: AffirmationList? {
    store.lists.first(where: { $0.id == list.id })
  }
  
  private var displayName: String {
    currentList?.name ?? list.name
  }
  
  private var affirmations: [Affirmation] {
    currentList?.affirmations ?? list.affirmations
  }
  
  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [
          Color(UIColor.systemBackground),
          Color.blue.opacity(0.05)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      VStack(spacing: 32) {
        Spacer()
        
        // Placeholder icon
        Image(systemName: "waveform.circle.fill")
          .font(.system(size: 120))
          .foregroundStyle(
            LinearGradient(
              gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
        
        // List name
        VStack(spacing: 8) {
          Text("Player Screen for:")
            .font(.subheadline)
            .foregroundColor(.secondary)
          
          Text(displayName)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
        }
        
        // Affirmation count
        Text("\(affirmations.count) affirmation\(affirmations.count == 1 ? "" : "s") to play")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(Color(UIColor.secondarySystemBackground))
          .cornerRadius(20)
        
        Spacer()
        
        // Placeholder controls (for future implementation)
        HStack(spacing: 40) {
          Button(action: {
            // Previous - future implementation
          }) {
            Image(systemName: "backward.fill")
              .font(.title2)
              .foregroundColor(.secondary)
          }
          
          Button(action: {
            // Play/Pause - future implementation
          }) {
            Image(systemName: "play.circle.fill")
              .font(.system(size: 72))
              .foregroundColor(.blue)
          }
          
          Button(action: {
            // Next - future implementation
          }) {
            Image(systemName: "forward.fill")
              .font(.title2)
              .foregroundColor(.secondary)
          }
        }
        .padding(.bottom, 60)
      }
      .padding()
    }
    .navigationTitle("Now Playing")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// Convenience initializer from PlayerDestination
extension PlayerView {
  init(destination: PlayerDestination) {
    self.list = destination.list
  }
}

struct PlayerView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      PlayerView(list: AffirmationList(name: "Morning Affirmations", affirmations: [
        Affirmation(id: UUID(), title: "I am confident"),
        Affirmation(id: UUID(), title: "I am successful")
      ]))
    }
    .environmentObject(AppStore())
  }
}


