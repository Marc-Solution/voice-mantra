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

/// Audio recording and playback service with 15-second recording limit
final class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()
    
    // MARK: - Constants
    static let maxRecordingDuration: TimeInterval = 15.0
    
    // MARK: - Published Properties
    @Published var isRecording: Bool = false
    @Published var currentDuration: TimeInterval = 0
    @Published var progress: Double = 0.0  // 0.0 to 1.0
    @Published var isPlaying: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var recordingError: String? = nil
    @Published var playbackError: String? = nil
    
    // MARK: - Private Properties
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var recordingSession: AVAudioSession { AVAudioSession.sharedInstance() }
    private var timer: Timer?
    private var currentTempURL: URL?
    private var onRecordingComplete: (() -> Void)?
    private var onPlaybackFinish: (() -> Void)?
    
    private override init() {
        super.init()
        // Configure audio session on initialization
        ensureAudioSession(for: .playback)
    }
    
    // MARK: - Audio Session Configuration
    
    /// Ensures the audio session is properly configured for the given mode
    /// Uses .playAndRecord for BOTH modes to ensure consistent behavior
    @discardableResult
    func ensureAudioSession(for mode: AudioSessionMode) -> Bool {
        let session = recordingSession
        
        do {
            // Use .playAndRecord for BOTH recording and playback
            // This prevents category switching issues that cause OSStatus -50
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [
                    .defaultToSpeaker,      // Route to loud speakers
                    .allowBluetooth,        // Support Bluetooth HFP
                    .allowBluetoothA2DP     // Support modern Bluetooth headphones (AAC/SBC)
                ]
            )
            
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
    
    // MARK: - Permissions
    
    /// Check current microphone permission status
    var microphonePermissionStatus: AVAudioSession.RecordPermission {
        recordingSession.recordPermission
    }
    
    /// Request microphone permission explicitly
    func requestPermission(completion: @escaping (Bool) -> Void) {
        switch recordingSession.recordPermission {
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
        
        guard recordingSession.recordPermission == .granted else {
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
        
        let session = recordingSession
        
        do {
            // Step 1: Ensure audio session is configured
            print("📱 Configuring audio session for playback...")
            ensureAudioSession(for: .playback)
            
            // Step 2: Force speaker output as fallback for "receiver" bug
            do {
                try session.overrideOutputAudioPort(.speaker)
                print("🔊 Output port overridden to speaker")
            } catch let overrideError as NSError {
                print("⚠️ Could not override output port: \(overrideError.localizedDescription)")
                // Continue anyway - this is just a fallback
            }
            
            // Log current session state
            print("🔊 Audio Session Category set to: \(session.category.rawValue)")
            print("   Current route: \(session.currentRoute.outputs.map { $0.portName })")
            
            // Step 3: Create the audio player
            print("📂 Loading audio from: \(url.lastPathComponent)")
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 1.0
            
            // Step 4: Prepare to play
            guard player?.prepareToPlay() == true else {
                throw NSError(domain: "AudioService", code: 10, userInfo: [NSLocalizedDescriptionKey: "prepareToPlay() failed"])
            }
            print("✅ Player prepared successfully")
            
            // Step 5: Start playback
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
        
        // Step 2: Configure audio session fresh for this playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
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
            player?.volume = 1.0
            
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
                player?.volume = 1.0
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
    
    /// Stops any current list playback
    func stopListPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        onPlaybackFinish = nil
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
