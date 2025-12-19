//
//  VoiceMantraApp.swift
//  VoiceMantra
//
//  Created by Marco Deb on 2025-12-11.
//

import SwiftUI
import SwiftData
import AVFoundation

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
    
    init() {
        // Configure audio session for playback
        // This ensures audio plays even with silent switch on or screen locked
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
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
}
