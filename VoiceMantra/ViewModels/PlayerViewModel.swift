//
//  PlayerViewModel.swift
//  MantraFlow
//
//  ViewModel for PlayerView using modern Observation framework.
//  Manages playback state, session tracking, and audio coordination.
//

import SwiftUI
import AVFoundation
import Observation

// MARK: - Playback State

/// Represents the current state of the audio playback session
enum PlaybackState: Equatable {
    case stopped
    case playing
    case pauseBetween  // Reflection pause between affirmations
}

// MARK: - Player ViewModel

/// Manages all playback logic, state, and session tracking for the player screen.
/// Uses the modern @Observable macro for efficient SwiftUI updates.
@Observable
final class PlayerViewModel {
    
    // MARK: - Configuration
    
    /// Minimum session duration (seconds) required to count toward streak
    private let minimumSessionDuration: TimeInterval = 5.0
    
    /// Delay before auto-starting playback (for smooth navigation transition)
    private let autoStartDelay: TimeInterval = 0.3
    
    /// Progress timer update interval (20 FPS for smooth animation)
    private let progressUpdateInterval: TimeInterval = 0.05
    
    // MARK: - Dependencies
    
    /// The affirmation list being played
    let list: AffirmationList
    
    /// Audio service for playback and mixer controls
    let audioService: AudioService
    
    /// Streak manager for tracking daily completions
    let streakManager: StreakManager
    
    // MARK: - Playback State
    
    /// Current index in the affirmations array
    var currentIndex: Int = 0
    
    /// Current playback state (stopped, playing, or paused between affirmations)
    var playbackState: PlaybackState = .stopped
    
    /// True when playback is about to loop back to the first affirmation
    var isLoopingBack: Bool = false
    
    // MARK: - Progress Tracking (High-Frequency for Smooth Animation)
    
    /// Progress value (0.0 to 1.0) for the circular progress ring
    /// Updated at 20 FPS for buttery-smooth animation
    var macroProgress: Double = 0.0
    
    /// High-frequency timer for smooth progress updates
    private var progressTimer: Timer?
    
    /// Timestamp when the current loop started (for progress calculation)
    private var loopStartTime: Date?
    
    /// Total duration of one complete loop (audio + gaps)
    private var totalLoopDuration: TimeInterval = 0
    
    // MARK: - UI State
    
    /// Controls visibility of the audio mixer sheet
    var isShowingMixer: Bool = false
    
    /// Controls visibility of the streak celebration toast
    var isShowingStreakToast: Bool = false
    
    // MARK: - Session Tracking
    
    /// Timestamp when the current session started
    private var sessionStartTime: Date?
    
    /// Accumulated duration of the current session
    private var sessionDuration: TimeInterval = 0
    
    // MARK: - Task Management
    
    /// The async task managing the playback sequence (for proper cancellation)
    private var playbackTask: Task<Void, Never>?
    
    // MARK: - User Settings
    
    /// Reflection pause duration in seconds (from UserDefaults/Settings)
    private var reflectionPause: Int {
        UserDefaults.standard.integer(forKey: "reflectionPause").nonZero ?? 10
    }
    
    // MARK: - Computed Properties
    
    /// Filtered and sorted affirmations ready for playback
    /// Excludes drafts (no audio) and muted items
    var affirmations: [Affirmation] {
        list.affirmations
            .filter { !$0.isDraft && !$0.isMuted }
            .sorted { first, second in
                if first.sortOrder != second.sortOrder {
                    return first.sortOrder < second.sortOrder
                }
                return first.createdAt < second.createdAt
            }
    }
    
    /// The currently displayed affirmation, if any
    var currentAffirmation: Affirmation? {
        guard !affirmations.isEmpty, currentIndex < affirmations.count else { return nil }
        return affirmations[currentIndex]
    }
    
    /// True if playback is active (playing audio or in reflection pause)
    var isActive: Bool {
        playbackState != .stopped
    }
    
    /// True if the list has playable content
    var hasPlayableContent: Bool {
        !affirmations.isEmpty
    }
    
    /// Progress text showing current position (e.g., "1 of 5")
    var progressText: String {
        "\(currentIndex + 1) of \(affirmations.count)"
    }
    
    /// Current streak count from the streak manager
    var currentStreak: Int {
        streakManager.currentStreak
    }
    
    // MARK: - Initialization
    
    init(
        list: AffirmationList,
        audioService: AudioService = .shared,
        streakManager: StreakManager = .shared
    ) {
        self.list = list
        self.audioService = audioService
        self.streakManager = streakManager
        
        // Configure audio session for background playback
        configureAudioSessionForBackground()
    }
    
    // MARK: - Audio Session Configuration
    
    /// Configures the audio session for background and lock-screen playback.
    /// Must be called before any audio playback begins.
    private func configureAudioSessionForBackground() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // .playback category enables background audio
            // No options needed - this allows playback when app is backgrounded or screen is locked
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            
            print("✅ Audio session configured for background playback")
        } catch {
            print("❌ Failed to configure audio session for background: \(error.localizedDescription)")
        }
    }
    
    deinit {
        // Ensure cleanup when ViewModel is deallocated
        playbackTask?.cancel()
        stopProgressTimer()
    }
    
    // MARK: - Public Actions
    
    /// Toggles between play and stop states
    func togglePlayback() {
        if isActive {
            stopAndRecordSession()
        } else {
            startPlayback()
        }
    }
    
    /// Called when the view appears - handles auto-start logic
    func onViewAppear() {
        guard !isActive, hasPlayableContent else {
            if isActive {
                print("▶️ Already playing - continuing current playback")
            } else {
                print("⚠️ No affirmations with audio - auto-play skipped")
            }
            return
        }
        
        // Delay for smooth navigation transition
        DispatchQueue.main.asyncAfter(deadline: .now() + autoStartDelay) { [weak self] in
            guard let self, !self.isActive else { return }
            print("🚀 Auto-starting playback on view appear")
            self.startPlayback()
        }
    }
    
    /// Called when the view disappears - ensures proper cleanup
    func onViewDisappear() {
        stopAndRecordSession()
    }
    
    /// Shows the audio mixer sheet
    func showMixer() {
        isShowingMixer = true
    }
    
    // MARK: - Playback Control
    
    /// Initiates the playback sequence
    private func startPlayback() {
        playbackTask?.cancel()
        
        sessionStartTime = Date()
        sessionDuration = 0
        
        // Calculate total loop duration and start progress tracking
        calculateTotalLoopDuration()
        startSmoothProgressTracking()
        
        playbackTask = Task { @MainActor in
            await runPlaybackSequence()
        }
    }
    
    /// Stops playback and records the session if meaningful
    func stopAndRecordSession() {
        // Calculate final session duration
        if let startTime = sessionStartTime {
            sessionDuration = Date().timeIntervalSince(startTime)
        }
        
        stopPlayback()
        recordSessionIfMeaningful()
        resetSessionTracking()
    }
    
    /// Immediately stops all playback without recording
    private func stopPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
        
        // Stop progress tracking
        stopProgressTimer()
        
        audioService.stopListPlayback()
        audioService.stopMacroProgressTracking()
        
        playbackState = .stopped
        isLoopingBack = false
        macroProgress = 0.0
        
        print("⏹️ Playback stopped")
    }
    
    // MARK: - Smooth Progress Tracking (20 FPS)
    
    /// Calculates the total duration of one complete loop
    /// Formula: Sum of all audio durations + (number of affirmations × reflection pause)
    private func calculateTotalLoopDuration() {
        var totalAudioDuration: TimeInterval = 0
        
        for affirmation in affirmations {
            if let url = affirmation.audioFileURL,
               FileManager.default.fileExists(atPath: url.path) {
                if let duration = getAudioDuration(url: url) {
                    totalAudioDuration += duration
                }
            }
        }
        
        // Total gaps = number of affirmations × reflection pause duration
        let totalGapDuration = TimeInterval(affirmations.count * reflectionPause)
        totalLoopDuration = totalAudioDuration + totalGapDuration
        
        print("📊 Loop Duration: \(String(format: "%.1f", totalLoopDuration))s " +
              "(Audio: \(String(format: "%.1f", totalAudioDuration))s + " +
              "Gaps: \(String(format: "%.1f", totalGapDuration))s)")
    }
    
    /// Gets the duration of an audio file
    private func getAudioDuration(url: URL) -> TimeInterval? {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player.duration
        } catch {
            print("⚠️ Could not get duration for: \(url.lastPathComponent)")
            return nil
        }
    }
    
    /// Starts the high-frequency progress timer (20 FPS)
    private func startSmoothProgressTracking() {
        stopProgressTimer()
        
        loopStartTime = Date()
        macroProgress = 0.0
        
        guard totalLoopDuration > 0 else {
            print("⚠️ Cannot track progress - no loop duration")
            return
        }
        
        // Create timer firing at 20 FPS for smooth analog motion
        progressTimer = Timer.scheduledTimer(withTimeInterval: progressUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        
        // Ensure timer runs during scrolling/interaction
        if let timer = progressTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        print("⏱️ Smooth progress tracking started (20 FPS)")
    }
    
    /// Updates the progress value based on elapsed time
    private func updateProgress() {
        guard let startTime = loopStartTime, totalLoopDuration > 0 else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let newProgress = min(elapsed / totalLoopDuration, 1.0)
        
        // Update on main thread for UI
        DispatchQueue.main.async { [weak self] in
            self?.macroProgress = newProgress
        }
    }
    
    /// Stops the progress timer and cleans up
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        loopStartTime = nil
    }
    
    /// Resets progress for a new loop iteration
    private func resetProgressForNewLoop() {
        loopStartTime = Date()
        macroProgress = 0.0
        print("🔄 Progress reset for new loop")
    }
    
    // MARK: - Playback Sequence
    
    /// Main playback loop - plays affirmations with reflection pauses
    /// Runs until cancelled by user or view disappearing
    @MainActor
    private func runPlaybackSequence() async {
        print("🎵 Starting playback sequence from index \(currentIndex)")
        
        guard hasPlayableContent else {
            print("⚠️ Cannot start playback - no affirmations with audio")
            playbackState = .stopped
            return
        }
        
        // Initialize audio channels
        audioService.playAllBackgroundTracks()
        
        // Infinite playback loop
        while !Task.isCancelled {
            // Play current affirmation
            if let audioURL = currentAffirmation?.audioFileURL,
               FileManager.default.fileExists(atPath: audioURL.path) {
                
                playbackState = .playing
                print("▶️ Playing affirmation \(currentIndex + 1)/\(affirmations.count)")
                
                await playAudioFile(at: audioURL)
                
                guard !Task.isCancelled else {
                    print("⏹️ Playback cancelled after audio finished")
                    return
                }
            } else {
                print("⚠️ Skipping index \(currentIndex) - no valid audio file")
            }
            
            // Reflection pause between affirmations
            playbackState = .pauseBetween
            isLoopingBack = currentIndex >= affirmations.count - 1
            
            print("⏸️ \(reflectionPause)s reflection pause\(isLoopingBack ? " before loop restart" : "")...")
            
            do {
                try await Task.sleep(nanoseconds: UInt64(reflectionPause) * 1_000_000_000)
            } catch {
                print("⏹️ Sleep interrupted - playback stopped")
                return
            }
            
            guard !Task.isCancelled else {
                print("⏹️ Playback cancelled during pause")
                return
            }
            
            // Advance to next affirmation or loop back
            advanceToNextAffirmation()
        }
    }
    
    /// Plays a single audio file and waits for completion
    @MainActor
    private func playAudioFile(at url: URL) async {
        await withCheckedContinuation { continuation in
            ensureAudioSessionActive()
            audioService.playAffirmation(url: url) {
                continuation.resume()
            }
        }
    }
    
    /// Re-activates the audio session before each audio file (safety reinforcement).
    /// The session is initially configured in init() for background playback.
    private func ensureAudioSessionActive() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
        } catch {
            print("⚠️ Audio session activation warning: \(error.localizedDescription)")
        }
    }
    
    /// Advances to the next affirmation or loops back to the beginning
    private func advanceToNextAffirmation() {
        if isLoopingBack {
            currentIndex = 0
            isLoopingBack = false
            resetProgressForNewLoop()
            print("🔁 Looped back to first affirmation")
        } else {
            currentIndex += 1
        }
    }
    
    // MARK: - Session Recording
    
    /// Records the session to streak manager if duration was meaningful
    private func recordSessionIfMeaningful() {
        guard sessionDuration > minimumSessionDuration else {
            print("⏹️ Session too short to count (\(Int(sessionDuration))s)")
            return
        }
        
        let streakIncreased = streakManager.recordCompletion(duration: sessionDuration)
        
        if streakIncreased {
            triggerStreakCelebration()
            print("🎉 Session completed! Duration: \(Int(sessionDuration))s, Streak: \(streakManager.currentStreak)")
        } else {
            print("📝 Session recorded (same day). Duration: \(Int(sessionDuration))s")
        }
    }
    
    /// Triggers haptic feedback and shows celebration toast
    private func triggerStreakCelebration() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        isShowingStreakToast = true
    }
    
    /// Resets session tracking state
    private func resetSessionTracking() {
        sessionStartTime = nil
        sessionDuration = 0
    }
}

// MARK: - Helper Extensions

private extension Int {
    /// Returns self if non-zero, otherwise nil (for optional chaining)
    var nonZero: Int? {
        self != 0 ? self : nil
    }
}
