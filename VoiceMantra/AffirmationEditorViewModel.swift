import Foundation
import AVFoundation
import Combine
import SwiftUI

final class AffirmationEditorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var text: String
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var tempAudioURL: URL?  // Temporary recording URL
    @Published var savedAudioFileName: String?  // Final saved filename in Documents
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var startDate: Date?
    
    // MARK: - Initializers
    init(text: String = "", existingAudioFileName: String? = nil) {
        self.text = text
        self.savedAudioFileName = existingAudioFileName
    }
    
    // MARK: - Permissions
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Recording
    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }
    
    private func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            // Record to temp directory first
            let url = Self.makeTempRecordingURL()
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            tempAudioURL = url
            isRecording = true
            startDate = Date()
            startTimer()
        } catch {
            print("Failed to start recording:", error)
            isRecording = false
            audioRecorder = nil
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        stopTimer()
        if let start = startDate {
            recordingDuration = Date().timeIntervalSince(start)
        }
        startDate = nil
    }
    
    // MARK: - Save Audio to Documents
    /// Saves the recorded audio to Documents directory with a UUID filename
    /// Returns the filename (not full path) for storage in SwiftData
    func saveAudioToDocuments() -> String? {
        guard let tempURL = tempAudioURL else {
            // If we have an existing saved file, return that
            return savedAudioFileName
        }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Generate unique filename with UUID
        let uniqueFileName = "\(UUID().uuidString).m4a"
        let destinationURL = documentsPath.appendingPathComponent(uniqueFileName)
        
        do {
            // If there's an existing saved file, delete it first
            if let existingFileName = savedAudioFileName {
                let existingURL = documentsPath.appendingPathComponent(existingFileName)
                try? fileManager.removeItem(at: existingURL)
            }
            
            // Copy temp file to Documents
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            
            // Clean up temp file
            try? fileManager.removeItem(at: tempURL)
            
            savedAudioFileName = uniqueFileName
            tempAudioURL = nil
            
            print("✅ Audio saved to Documents: \(uniqueFileName)")
            return uniqueFileName
        } catch {
            print("❌ Failed to save audio to Documents:", error)
            return nil
        }
    }
    
    /// Clears any temporary recordings without saving
    func clearTempRecording() {
        if let tempURL = tempAudioURL {
            try? FileManager.default.removeItem(at: tempURL)
        }
        tempAudioURL = nil
        recordingDuration = 0
    }
    
    // MARK: - Timer
    private func startTimer() {
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
                guard let s = self else { return }
                if let start = s.startDate {
                    s.recordingDuration = Date().timeIntervalSince(start)
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Helpers
    private static func makeTempRecordingURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "temp-recording-\(UUID().uuidString).m4a"
        return tempDir.appendingPathComponent(filename)
    }
    
    /// Check if there's any audio (either temp or saved)
    var hasAudio: Bool {
        tempAudioURL != nil || savedAudioFileName != nil
    }
    
    /// Get the current playable audio URL
    var currentAudioURL: URL? {
        if let tempURL = tempAudioURL {
            return tempURL
        }
        if let savedFileName = savedAudioFileName {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return documentsPath.appendingPathComponent(savedFileName)
        }
        return nil
    }
}
