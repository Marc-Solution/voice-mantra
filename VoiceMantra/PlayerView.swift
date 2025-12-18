//
//  PlayerView.swift
//  VoiceMantra
//
//  Created for VoiceMantra
//

import SwiftUI
import SwiftData
import AVFoundation

/// Wrapper type for programmatic navigation to PlayerView
struct PlayerDestination: Hashable {
    let listId: PersistentIdentifier
    let list: AffirmationList
    
    init(list: AffirmationList) {
        self.listId = list.persistentModelID
        self.list = list
    }
    
    static func == (lhs: PlayerDestination, rhs: PlayerDestination) -> Bool {
        lhs.listId == rhs.listId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(listId)
    }
}

struct PlayerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let list: AffirmationList
    
    @State private var currentIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    
    private var affirmations: [Affirmation] {
        list.affirmations.sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    private var currentAffirmation: Affirmation? {
        guard !affirmations.isEmpty, currentIndex < affirmations.count else { return nil }
        return affirmations[currentIndex]
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
                
                // Waveform icon
                Image(systemName: isPlaying ? "waveform.circle.fill" : "waveform.circle")
                    .font(.system(size: 120))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                    .animation(.easeInOut(duration: 0.3), value: isPlaying)
                
                // List name & current affirmation
                VStack(spacing: 12) {
                    Text(list.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let affirmation = currentAffirmation {
                        Text(affirmation.text)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .animation(.easeInOut, value: currentIndex)
                    } else {
                        Text("No affirmations to play")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress indicator
                if !affirmations.isEmpty {
                    Text("\(currentIndex + 1) of \(affirmations.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                }
                
                Spacer()
                
                // Playback controls
                HStack(spacing: 40) {
                    Button(action: previousAffirmation) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(currentIndex > 0 ? .primary : .secondary.opacity(0.5))
                    }
                    .disabled(currentIndex == 0)
                    
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(currentAffirmation?.audioFileName != nil ? .blue : .secondary)
                    }
                    .disabled(currentAffirmation?.audioFileName == nil)
                    
                    Button(action: nextAffirmation) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(currentIndex < affirmations.count - 1 ? .primary : .secondary.opacity(0.5))
                    }
                    .disabled(currentIndex >= affirmations.count - 1)
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopPlayback()
        }
    }
    
    // MARK: - Playback Controls
    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            playCurrentAffirmation()
        }
    }
    
    private func playCurrentAffirmation() {
        guard let affirmation = currentAffirmation,
              let url = affirmation.audioFileURL else { return }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = PlayerAudioDelegate.shared
            PlayerAudioDelegate.shared.onFinish = { [self] in
                DispatchQueue.main.async {
                    self.isPlaying = false
                    // Auto-advance to next affirmation
                    if self.currentIndex < self.affirmations.count - 1 {
                        self.currentIndex += 1
                        // Small delay before playing next
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.playCurrentAffirmation()
                        }
                    }
                }
            }
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
            isPlaying = false
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
    
    private func previousAffirmation() {
        stopPlayback()
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    private func nextAffirmation() {
        stopPlayback()
        if currentIndex < affirmations.count - 1 {
            currentIndex += 1
        }
    }
}

// MARK: - Audio Player Delegate
private class PlayerAudioDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = PlayerAudioDelegate()
    var onFinish: (() -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AffirmationList.self, Affirmation.self, configurations: config)
    let sampleList = AffirmationList(title: "Morning Affirmations")
    
    return NavigationStack {
        PlayerView(list: sampleList)
    }
    .modelContainer(container)
}
