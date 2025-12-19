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

/// Playback state for the player
enum PlaybackState: Equatable {
    case stopped
    case playing
    case pauseBetween  // 10-second reflection pause between affirmations
}

struct PlayerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let list: AffirmationList
    
    // MARK: - State
    @State private var currentIndex: Int = 0
    @State private var playbackState: PlaybackState = .stopped
    @State private var pauseCountdown: Int = 5
    @State private var countdownTimer: Timer?
    
    /// Task that manages the entire playback sequence
    @State private var playbackTask: Task<Void, Never>?
    
    /// Strong reference to AudioService
    @StateObject private var audioService = AudioService.shared
    
    // MARK: - Computed Properties
    private var affirmations: [Affirmation] {
        list.affirmations
            .filter { !$0.isDraft }  // Only play affirmations with audio
            .sorted(by: { $0.createdAt < $1.createdAt })
    }
    
    private var currentAffirmation: Affirmation? {
        guard !affirmations.isEmpty, currentIndex < affirmations.count else { return nil }
        return affirmations[currentIndex]
    }
    
    /// True if actively playing audio or in pause-between state
    private var isActive: Bool {
        playbackState != .stopped
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
                
                // Waveform icon with animation
                ZStack {
                    Image(systemName: playbackState == .playing ? "waveform.circle.fill" : "waveform.circle")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        .animation(.easeInOut(duration: 0.3), value: playbackState)
                    
                    // Countdown overlay during pause
                    if playbackState == .pauseBetween {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Text("\(pauseCountdown)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
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
                    } else if affirmations.isEmpty {
                        Text("No recorded affirmations to play")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    // Status text
                    if playbackState == .pauseBetween {
                        Text("Next affirmation in \(pauseCountdown)s...")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                }
                
                // Progress indicator
                if !affirmations.isEmpty {
                    HStack(spacing: 8) {
                        Text("\(currentIndex + 1) of \(affirmations.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isActive {
                            Circle()
                                .fill(playbackState == .playing ? Color.green : Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
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
                    .disabled(currentIndex == 0 || isActive)
                    
                    Button(action: togglePlayback) {
                        Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(currentAffirmation?.audioFileName != nil ? .blue : .secondary)
                    }
                    .disabled(affirmations.isEmpty)
                    
                    Button(action: nextAffirmation) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(currentIndex < affirmations.count - 1 ? .primary : .secondary.opacity(0.5))
                    }
                    .disabled(currentIndex >= affirmations.count - 1 || isActive)
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
        if isActive {
            stopPlayback()
        } else {
            startPlaybackSequence()
        }
    }
    
    /// Starts the async playback sequence
    private func startPlaybackSequence() {
        // Cancel any existing task
        playbackTask?.cancel()
        
        playbackTask = Task {
            await playSequence()
        }
    }
    
    /// Async function that plays through all affirmations with 5-second gaps
    @MainActor
    private func playSequence() async {
        print("🎵 Starting playback sequence from index \(currentIndex)")
        
        while currentIndex < affirmations.count {
            // Check for cancellation
            if Task.isCancelled {
                print("⏹️ Playback sequence cancelled")
                return
            }
            
            guard let affirmation = affirmations[safe: currentIndex],
                  let url = affirmation.audioFileURL else {
                print("⚠️ Skipping index \(currentIndex) - no valid audio URL")
                currentIndex += 1
                continue
            }
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("❌ File not found at: \(url)")
                currentIndex += 1
                continue
            }
            
            // Play current affirmation
            playbackState = .playing
            print("▶️ Playing affirmation \(currentIndex + 1)/\(affirmations.count): \(url.lastPathComponent)")
            
            await playAudio(url: url)
            
            // Check for cancellation after playback
            if Task.isCancelled {
                print("⏹️ Playback sequence cancelled after audio finished")
                return
            }
            
            // Check if there are more affirmations
            if currentIndex < affirmations.count - 1 {
                // Enter pause state for reflection time
                playbackState = .pauseBetween
                pauseCountdown = 10
                print("⏸️ 10-second reflection pause before next affirmation...")
                
                // Start countdown timer for UI
                startCountdownTimer()
                
                // Wait 10 seconds for user reflection (using Task.sleep for modern async/await)
                do {
                    try await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                } catch {
                    // Task was cancelled
                    print("⏹️ Sleep interrupted - playback stopped")
                    stopCountdownTimer()
                    return
                }
                
                stopCountdownTimer()
                
                // Check for cancellation after sleep
                if Task.isCancelled {
                    print("⏹️ Playback sequence cancelled during pause")
                    return
                }
                
                // Move to next affirmation
                currentIndex += 1
            } else {
                // No more affirmations - sequence complete
                break
            }
        }
        
        // Sequence finished naturally
        playbackState = .stopped
        print("✅ Playlist finished")
    }
    
    /// Plays a single audio file and waits for completion
    @MainActor
    private func playAudio(url: URL) async {
        await withCheckedContinuation { continuation in
            // Configure audio session fresh
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
                try session.setActive(true)
                print("✅ Audio session configured")
            } catch {
                print("⚠️ Audio session warning: \(error.localizedDescription)")
            }
            
            // Use AudioService for robust playback
            audioService.playAffirmation(url: url) {
                continuation.resume()
            }
        }
    }
    
    /// Starts the countdown timer for UI feedback
    private func startCountdownTimer() {
        stopCountdownTimer()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if pauseCountdown > 1 {
                pauseCountdown -= 1
            }
        }
    }
    
    /// Stops the countdown timer
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func stopPlayback() {
        // Cancel the playback task
        playbackTask?.cancel()
        playbackTask = nil
        
        // Stop countdown
        stopCountdownTimer()
        
        // Stop any playing audio
        audioService.stopListPlayback()
        
        playbackState = .stopped
        print("⏹️ Playback stopped by user")
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

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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
