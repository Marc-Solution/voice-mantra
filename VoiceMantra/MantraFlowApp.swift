//
//  MantraFlowApp.swift
//  MantraFlow
//
//  Created by Marco Deb on 2025-12-11.
//

import SwiftUI
import SwiftData
import AVFoundation

@main
struct MantraFlowApp: App {
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
    
    init() {
        // Configure audio session for playback
        // This ensures audio plays even with silent switch on or screen locked
        configureAudioSession()
        
        // Configure global navigation bar appearance for brand styling
        configureNavigationAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)  // Force dark mode globally
                .tint(.brandText)  // Global tint: white for all system controls
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✅ Audio session configured for playback")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
    
    private func configureNavigationAppearance() {
        // Standard navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()  // Transparent, no separator
        appearance.backgroundColor = UIColor(Color.brandBackground)
        appearance.shadowColor = .clear  // Remove the thin grey separator line
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.brandText)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.brandText)
        ]
        
        // Back button and interactive elements: white (brandText)
        UINavigationBar.appearance().tintColor = UIColor(Color.brandText)
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
