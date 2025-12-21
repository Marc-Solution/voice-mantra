//
//  AudioService.swift
//  VoiceMantra
//
//  Created by Marco Deb on 2025-12-11.
//

import Foundation
import AVFoundation
import Combine

/// Audio session mode for configuration
enum AudioSessionMode {
    case recording
    case playback
}

/// Audio recording and playback service with 15-second recording limit and 4-channel mixer
final class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()
    
    // MARK: - Constants
    static let maxRecordingDuration: TimeInterval = 15.0
    
    // MARK: - Published Properties (Recording)
    @Published var isRecording: Bool = false
    @Published var currentDuration: TimeInterval = 0
    @Published var progress: Double = 0.0  // 0.0 to 1.0
    @Published var isPlaying: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var recordingError: String? = nil
    @Published var playbackError: String? = nil
    
    // MARK: - Published Properties (4-Channel Mixer Volumes)
    @Published var voiceVolume: Float = 1.0      // Default: 100%
    @Published var musicVolume: Float = 0.4      // Default: 40%
    @Published var natureVolume: Float = 0.2     // Default: 20%
    @Published var binauralVolume: Float = 0.15  // Default: 15%
    
    // MARK: - Private Properties (Recording)
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?  // Voice/affirmation player
    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }
    private var timer: Timer?
    private var currentTempURL: URL?
    private var onRecordingComplete: (() -> Void)?
    private var onPlaybackFinish: (() -> Void)?
    
    // MARK: - Private Properties (4-Channel Mixer)
    private var ambientPlayer: AVAudioPlayer?   // Background music
    private var naturePlayer: AVAudioPlayer?    // Nature sounds
    private var binauralPlayer: AVAudioPlayer?  // Binaural beats
    
    private override init() {
        super.init()
        // Configure audio session on initialization
        ensureAudioSession(for: .playback)
        // Setup background audio tracks
        setupBackgroundTracks()
    }
    
    // MARK: - 4-Channel Mixer Setup
    
    /// Loads and configures all background audio tracks
    private func setupBackgroundTracks() {
        // Load Ambient Music
        if let url = Bundle.main.url(forResource: "AmbientMusic", withExtension: "mp3") {
            do {
                ambientPlayer = try AVAudioPlayer(contentsOf: url)
                ambientPlayer?.numberOfLoops = -1  // Infinite loop
                ambientPlayer?.volume = musicVolume
                ambientPlayer?.prepareToPlay()
                print("✅ Loaded AmbientMusic.mp3")
            } catch {
                print("⚠️ Failed to load AmbientMusic.mp3: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ AmbientMusic.mp3 not found in bundle")
        }
        
        // Load Nature Sounds
        if let url = Bundle.main.url(forResource: "NatureSounds", withExtension: "mp3") {
            do {
                naturePlayer = try AVAudioPlayer(contentsOf: url)
                naturePlayer?.numberOfLoops = -1  // Infinite loop
                naturePlayer?.volume = natureVolume
                naturePlayer?.prepareToPlay()
                print("✅ Loaded NatureSounds.mp3")
            } catch {
                print("⚠️ Failed to load NatureSounds.mp3: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ NatureSounds.mp3 not found in bundle")
        }
        
        // Load Binaural Beats
        if let url = Bundle.main.url(forResource: "Bineural5Hz", withExtension: "mp3") {
            do {
                binauralPlayer = try AVAudioPlayer(contentsOf: url)
                binauralPlayer?.numberOfLoops = -1  // Infinite loop
                binauralPlayer?.volume = binauralVolume
                binauralPlayer?.prepareToPlay()
                print("✅ Loaded Bineural5Hz.mp3")
            } catch {
                print("⚠️ Failed to load Bineural5Hz.mp3: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Bineural5Hz.mp3 not found in bundle")
        }
    }
    
    // MARK: - 4-Channel Mixer Controls
    
    /// Starts all background tracks simultaneously
    func playAllBackgroundTracks() {
        print("🎵 Starting all background tracks...")
        ambientPlayer?.play()
        naturePlayer?.play()
        binauralPlayer?.play()
    }
    
    /// Stops all background tracks
    func stopAllBackgroundTracks() {
        print("⏹️ Stopping all background tracks...")
        ambientPlayer?.stop()
        naturePlayer?.stop()
        binauralPlayer?.stop()
        
        // Reset playback position
        ambientPlayer?.currentTime = 0
        naturePlayer?.currentTime = 0
        binauralPlayer?.currentTime = 0
    }
    
    /// Updates the voice track volume
    func setVoiceVolume(_ volume: Float) {
        voiceVolume = volume
        player?.volume = volume
    }
    
    /// Updates the ambient music volume
    func setMusicVolume(_ volume: Float) {
        musicVolume = volume
        ambientPlayer?.volume = volume
    }
    
    /// Updates the nature sounds volume
    func setNatureVolume(_ volume: Float) {
        natureVolume = volume
        naturePlayer?.volume = volume
    }
    
    /// Updates the binaural beats volume
    func setBinauralVolume(_ volume: Float) {
        binauralVolume = volume
        binauralPlayer?.volume = volume
    }
    
    // MARK: - Audio Session Configuration
    
    /// Ensures the audio session is properly configured for the given mode
    @discardableResult
    func ensureAudioSession(for mode: AudioSessionMode) -> Bool {
        let session = audioSession
        
        do {
            switch mode {
            case .recording:
                // Use .playAndRecord for recording mode
                // Note: .allowBluetooth is deprecated in iOS 17+, use .allowBluetoothA2DP instead
                try session.setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [
                        .defaultToSpeaker,
                        .allowBluetoothA2DP
                    ]
                )
            case .playback:
                // Use .playback for playback mode (fixes OSStatus -50)
                // DO NOT use .defaultToSpeaker with .playback category
                try session.setCategory(
                    .playback,
                    mode: .default,
                    options: [
                        .mixWithOthers  // Allow mixing with other audio if needed
                    ]
                )
            }
            
            // Activate the session
            do {
                try session.setActive(true)
                print("✅ Audio session activated for \(mode)")
            } catch let activationError as NSError {
                print("⚠️ Failed to activate audio session: \(activationError.localizedDescription)")
                print("   OSStatus: \(activationError.code)")
                // Continue anyway - sometimes activation fails but playback still works
            }
            
            print("🔊 Audio Session Category set to: \(session.category.rawValue)")
            print("   Options: \(session.categoryOptions)")
            print("   Mode: \(mode)")
            
            return true
            
        } catch let error as NSError {
            print("❌ Failed to configure audio session for \(mode): \(error.localizedDescription)")
            print("   OSStatus: \(error.code)")
            return false
        }
    }
    
    /// Legacy function for backward compatibility
    func configureAudioSessionForPlayback() {
        ensureAudioSession(for: .playback)
    }
    
    // MARK: - Permissions (iOS 17+)
    
    /// Check if microphone permission is granted
    var isMicrophonePermissionGranted: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }
    
    /// Request microphone permission explicitly using iOS 17+ API
    func requestPermission(completion: @escaping (Bool) -> Void) {
        let currentPermission = AVAudioApplication.shared.recordPermission
        
        switch currentPermission {
        case .granted:
            DispatchQueue.main.async {
                self.permissionDenied = false
                completion(true)
            }
        case .denied:
            DispatchQueue.main.async {
                self.permissionDenied = true
                completion(false)
            }
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionDenied = !granted
                    completion(granted)
                }
            }
        @unknown default:
            DispatchQueue.main.async {
                self.permissionDenied = true
                completion(false)
            }
        }
    }
    
    // MARK: - Recording
    
    /// Starts recording to a temporary file with 15-second auto-stop
    func startRecording(onComplete: (() -> Void)? = nil) {
        guard !isRecording else { return }
        
        recordingError = nil
        playbackError = nil
        onRecordingComplete = onComplete
        
        // Use modern iOS 17+ permission check
        guard isMicrophonePermissionGranted else {
            print("❌ Microphone permission not granted. Cannot start recording.")
            permissionDenied = true
            recordingError = "Microphone permission denied. Please enable in Settings."
            return
        }
        
        // Configure audio session for recording
        guard ensureAudioSession(for: .recording) else {
            recordingError = "Failed to configure audio session"
            return
        }
        
        do {
            let fileURL = Self.createTempFile()
            currentTempURL = fileURL
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            
            guard recorder?.prepareToRecord() == true else {
                throw NSError(domain: "AudioService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare audio recorder"])
            }
            
            guard recorder?.record() == true else {
                throw NSError(domain: "AudioService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"])
            }
            
            isRecording = true
            currentDuration = 0
            progress = 0
            startTimer()
            
            print("🎙️ Recording started at: \(fileURL.lastPathComponent)")
            
        } catch let error as NSError {
            handleRecordingError(error)
        }
    }
    
    private func handleRecordingError(_ error: NSError) {
        print("❌ Failed to start recording: \(error.localizedDescription)")
        print("   Error domain: \(error.domain), code: \(error.code)")
        
        isRecording = false
        recorder = nil
        currentTempURL = nil
        
        if error.domain == NSOSStatusErrorDomain {
            switch error.code {
            case Int(kAudioServicesNoHardwareError):
                recordingError = "No audio hardware available"
            case Int(kAudioServicesBadPropertySizeError):
                recordingError = "Audio configuration error"
            default:
                recordingError = "Audio error (OSStatus: \(error.code))"
            }
        } else {
            recordingError = error.localizedDescription
        }
    }
    
    @discardableResult
    func stopRecording() -> URL? {
        guard isRecording else { return currentTempURL }
        
        recorder?.stop()
        stopTimer()
        isRecording = false
        
        let url = currentTempURL
        recorder = nil
        
        // Keep session in .playAndRecord for seamless playback
        ensureAudioSession(for: .playback)
        
        print("🛑 Recording stopped. Duration: \(String(format: "%.1f", currentDuration))s")
        return url
    }
    
    var tempRecordingURL: URL? {
        currentTempURL
    }
    
    func clearTempRecording() {
        if let url = currentTempURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentTempURL = nil
        currentDuration = 0
        progress = 0
    }
    
    // MARK: - Playback
    
    /// Plays audio from a URL for preview with robust error handling
    func playPreview(url: URL, onFinish: (() -> Void)? = nil) {
        stopPreview()
        playbackError = nil
        onPlaybackFinish = onFinish
        
        do {
            // Step 1: Configure audio session for playback (NO .defaultToSpeaker!)
            print("📱 Configuring audio session for playback...")
            let session = audioSession
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            
            // Log current session state
            print("🔊 Audio Session Category set to: \(session.category.rawValue)")
            print("   Current route: \(session.currentRoute.outputs.map { $0.portName })")
            
            // Step 2: Create the audio player
            print("📂 Loading audio from: \(url.lastPathComponent)")
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = voiceVolume
            
            // Step 3: Prepare to play
            guard player?.prepareToPlay() == true else {
                throw NSError(domain: "AudioService", code: 10, userInfo: [NSLocalizedDescriptionKey: "prepareToPlay() failed"])
            }
            print("✅ Player prepared successfully")
            
            // Step 4: Start playback
            print("▶️ Starting playback...")
            let playSuccess = player?.play() ?? false
            
            if playSuccess {
                isPlaying = true
                print("✅ Playback started successfully")
            } else {
                throw NSError(domain: "AudioService", code: 11, userInfo: [NSLocalizedDescriptionKey: "play() returned false"])
            }
            
        } catch let error as NSError {
            handlePlaybackError(error)
        }
    }
    
    private func handlePlaybackError(_ error: NSError) {
        print("❌ Playback failed: \(error.localizedDescription)")
        print("   Error domain: \(error.domain)")
        print("   OSStatus/Code: \(error.code)")
        
        isPlaying = false
        player = nil
        
        // OSStatus -50 = kAudio_ParamError (invalid parameter)
        if error.code == -50 {
            playbackError = "Audio parameter error. Try recording again."
            print("💡 OSStatus -50 usually means the audio file or session state is invalid")
        } else if error.domain == NSOSStatusErrorDomain {
            playbackError = "Playback error (OSStatus: \(error.code))"
        } else {
            playbackError = error.localizedDescription
        }
    }
    
    func stopPreview() {
        player?.stop()
        player = nil
        isPlaying = false
        onPlaybackFinish = nil
    }
    
    // MARK: - List Playback (for PlayerView)
    
    /// Plays an affirmation audio file with robust error handling and retry logic
    /// - Parameters:
    ///   - url: The URL of the audio file
    ///   - onFinish: Callback when playback completes (successfully or not)
    func playAffirmation(url: URL, onFinish: @escaping () -> Void) {
        // Reset state
        playbackError = nil
        onPlaybackFinish = onFinish
        
        // Step 1: Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ File not found at: \(url)")
            playbackError = "Audio file not found"
            onFinish()
            return
        }
        
        print("▶️ Starting playback for: \(url.lastPathComponent)")
        
        // Step 2: Configure audio session for playback (NO .defaultToSpeaker with .playback!)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            print("✅ Audio session configured for playback")
        } catch {
            print("⚠️ Audio session configuration warning: \(error.localizedDescription)")
            // Continue anyway - sometimes playback still works
        }
        
        // Step 3: Create player with retry logic
        do {
            player = try createPlayer(from: url)
            player?.delegate = self
            player?.volume = voiceVolume  // Apply current voice volume from mixer
            
            guard player?.prepareToPlay() == true else {
                throw NSError(domain: "AudioService", code: 20, userInfo: [NSLocalizedDescriptionKey: "prepareToPlay() failed"])
            }
            
            // Step 4: Attempt playback
            if let success = player?.play(), success {
                isPlaying = true
                print("✅ Playback started for: \(url.lastPathComponent)")
            } else {
                // Retry once
                print("⚠️ First play attempt failed, retrying...")
                player = nil
                player = try createPlayer(from: url)
                player?.delegate = self
                player?.volume = voiceVolume
                _ = player?.prepareToPlay()
                
                if let retrySuccess = player?.play(), retrySuccess {
                    isPlaying = true
                    print("✅ Retry successful for: \(url.lastPathComponent)")
                } else {
                    throw NSError(domain: "AudioService", code: 21, userInfo: [NSLocalizedDescriptionKey: "Playback failed after retry"])
                }
            }
            
        } catch {
            print("❌ Failed to play affirmation: \(error.localizedDescription)")
            playbackError = error.localizedDescription
            isPlaying = false
            player = nil
            onFinish()
        }
    }
    
    /// Creates an AVAudioPlayer from a URL
    private func createPlayer(from url: URL) throws -> AVAudioPlayer {
        return try AVAudioPlayer(contentsOf: url)
    }
    
    /// Stops any current list playback and all background tracks
    func stopListPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        onPlaybackFinish = nil
        
        // Also stop background tracks
        stopAllBackgroundTracks()
        
        print("⏹️ List playback stopped")
    }
    
    // MARK: - File Management
    
    func saveTempToDocuments() -> String? {
        guard let tempURL = currentTempURL else { return nil }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let uniqueFileName = "\(UUID().uuidString).m4a"
        let destinationURL = documentsPath.appendingPathComponent(uniqueFileName)
        
        do {
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            try? fileManager.removeItem(at: tempURL)
            currentTempURL = nil
            
            print("✅ Audio saved to Documents: \(uniqueFileName)")
            return uniqueFileName
        } catch {
            print("❌ Failed to save audio:", error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private static func createTempFile() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "recording-\(UUID().uuidString).m4a"
        return tempDir.appendingPathComponent(filename)
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.currentDuration = self.recorder?.currentTime ?? 0
            self.progress = min(self.currentDuration / Self.maxRecordingDuration, 1.0)
            
            if self.currentDuration >= Self.maxRecordingDuration {
                self.stopRecording()
                self.onRecordingComplete?()
                self.onRecordingComplete = nil
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioService: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("⚠️ Recorder encode error:", error.localizedDescription)
                self?.recordingError = "Recording error: \(error.localizedDescription)"
            }
            self?.isRecording = false
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            if !flag {
                print("⚠️ Recording did not finish successfully")
                self?.recordingError = "Recording was interrupted"
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.onPlaybackFinish?()
            self?.onPlaybackFinish = nil
            
            if flag {
                print("✅ Playback finished successfully")
            } else {
                print("⚠️ Playback did not finish successfully")
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error as NSError? {
                print("⚠️ Player decode error: \(error.localizedDescription)")
                print("   OSStatus: \(error.code)")
                self?.playbackError = "Decode error: \(error.localizedDescription)"
            }
            self?.isPlaying = false
        }
    }
}
