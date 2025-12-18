//
//  VoiceMantraApp.swift
//  VoiceMantra
//
//  Created by Marco Deb on 2025-12-11.
//

import SwiftUI
import SwiftData

@main
struct VoiceMantraApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AffirmationList.self,
            Affirmation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
