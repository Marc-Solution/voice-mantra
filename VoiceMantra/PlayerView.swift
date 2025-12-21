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
    @State private var pauseCountdown: Int = 10
    @State private var countdownTimer: Timer?
    @State private var isLoopingBack: Bool = false  // True when about to restart from beginning
    @State private var showingMixer: Bool = false   // Mixer sheet visibility
    
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
                        Text(isLoopingBack 
                             ? "Restarting in \(pauseCountdown)s..." 
                             : "Next affirmation in \(pauseCountdown)s...")
                            .font(.caption)
                            .foregroundColor(isLoopingBack ? .orange : .blue)
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
                
                // Playback Control Group
                VStack(spacing: 30) {
                    // Mixer Button - larger circular with blur background
                    Button(action: { showingMixer = true }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 65, height: 65)
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.primary)
                                .shadow(color: Color.white.opacity(0.8), radius: 1, x: 0, y: 0)
                        }
                    }
                    
                    // Play/Stop button - single-button experience
                    Button(action: togglePlayback) {
                        Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 88))
                            .foregroundColor(affirmations.isEmpty ? .secondary : .blue)
                            .shadow(color: Color.blue.opacity(isActive ? 0.4 : 0.2), radius: 12, x: 0, y: 6)
                    }
                    .disabled(affirmations.isEmpty)
                    .scaleEffect(isActive ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isActive)
                }
                .padding(.bottom, 60)
      }
      .padding()
    }
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMixer) {
            MixerSheetView(audioService: audioService)
        }
        .onAppear {
            autoStartPlayback()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    // MARK: - Auto-Start Logic
    
    /// Automatically starts playback when the view appears (if not already playing)
    private func autoStartPlayback() {
        // Guard: Don't restart if already playing
        guard !isActive else {
            print("▶️ Already playing - continuing current playback")
            return
        }
        
        // Guard: Ensure we have affirmations with audio to play
        guard !affirmations.isEmpty else {
            print("⚠️ No affirmations with audio - auto-play skipped")
            return
        }
        
        // Start playback with a small delay for smooth navigation transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Double-check we haven't started playing during the delay
            guard !isActive else { return }
            
            print("🚀 Auto-starting playback on view appear")
            startPlaybackSequence()
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
    
    /// Async function that plays through all affirmations in an infinite loop with 10-second reflection gaps
    @MainActor
    private func playSequence() async {
        print("🎵 Starting infinite playback sequence from index \(currentIndex)")
        
        // Guard: Ensure list is not empty to prevent infinite crash loop
        guard !affirmations.isEmpty else {
            print("⚠️ Cannot start playback - no affirmations with audio")
            playbackState = .stopped
            return
        }
        
        // Start all 4 channels (voice will be played per-affirmation)
        audioService.playAllBackgroundTracks()
        
        // Infinite loop - plays until user stops
        while true {
            // Check for cancellation at start of each loop iteration
            if Task.isCancelled {
                print("⏹️ Playback sequence cancelled")
                return
            }
            
            // Play current affirmation
            if let affirmation = affirmations[safe: currentIndex],
               let url = affirmation.audioFileURL,
               FileManager.default.fileExists(atPath: url.path) {
                
                playbackState = .playing
                print("▶️ Playing affirmation \(currentIndex + 1)/\(affirmations.count): \(url.lastPathComponent)")
                
                await playAudio(url: url)
                
                // Check for cancellation after playback
                if Task.isCancelled {
                    print("⏹️ Playback sequence cancelled after audio finished")
                    return
                }
            } else {
                print("⚠️ Skipping index \(currentIndex) - no valid audio or file not found")
            }
            
            // 10-second reflection pause (always, including before looping back)
            playbackState = .pauseBetween
            pauseCountdown = 10
            
            // Check if we're at the last affirmation (about to loop)
            isLoopingBack = currentIndex >= affirmations.count - 1
            if isLoopingBack {
                print("🔄 Loop Restarting: Moving from last affirmation back to the beginning.")
                print("⏸️ 10-second reflection pause before restarting loop...")
            } else {
                print("⏸️ 10-second reflection pause before next affirmation...")
            }
            
            // Start countdown timer for UI
            startCountdownTimer()
            
            // Wait 10 seconds for user reflection
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
            
            // Move to next affirmation or loop back to beginning
            if isLoopingBack {
                currentIndex = 0
                isLoopingBack = false  // Reset for next iteration
                print("🔁 Looped back to first affirmation")
            } else {
                currentIndex += 1
            }
        }
    }
    
    /// Plays a single audio file and waits for completion
    @MainActor
    private func playAudio(url: URL) async {
        await withCheckedContinuation { continuation in
            // Configure audio session (NO .defaultToSpeaker with .playback category!)
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [])
                try session.setActive(true)
                print("✅ Audio session configured for voice playback")
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
        
        // Reset state
        playbackState = .stopped
        isLoopingBack = false
        print("⏹️ Playback stopped by user")
    }
    
}

// MARK: - Mixer Sheet View

struct MixerSheetView: View {
    @ObservedObject var audioService: AudioService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                    
                    Text("Audio Mixer")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Adjust the volume levels for each audio channel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
                
                // Sliders with balanced spacing
                VStack(spacing: 22) {
                    MixerSlider(
                        label: "Voice",
                        icon: "waveform",
                        color: .blue,
                        value: Binding(
                            get: { audioService.voiceVolume },
                            set: { audioService.setVoiceVolume($0) }
                        )
                    )
                    
                    MixerSlider(
                        label: "Music",
                        icon: "music.note",
                        color: .purple,
                        value: Binding(
                            get: { audioService.musicVolume },
                            set: { audioService.setMusicVolume($0) }
                        )
                    )
                    
                    MixerSlider(
                        label: "Nature",
                        icon: "leaf.fill",
                        color: .green,
                        value: Binding(
                            get: { audioService.natureVolume },
                            set: { audioService.setNatureVolume($0) }
                        )
                    )
                    
                    MixerSlider(
                        label: "Binaural",
                        icon: "brain.head.profile",
                        color: .orange,
                        value: Binding(
                            get: { audioService.binauralVolume },
                            set: { audioService.setBinauralVolume($0) }
                        )
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .padding()
            .padding(.bottom, 80)  // Aggressive clearance from home gesture area
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Mixer Slider Component

struct MixerSlider: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var value: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Label row
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            // Slider row with percentage vertically centered
            HStack(spacing: 12) {
                Slider(value: $value, in: 0...1, step: 0.05)
                    .tint(color)
                
                Text("\(Int(value * 100))%")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .trailing)
                    .monospacedDigit()
            }
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
