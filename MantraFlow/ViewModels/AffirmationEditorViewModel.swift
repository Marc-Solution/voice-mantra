import Foundation
import AVFoundation
import Combine
import SwiftUI

final class AffirmationEditorViewModel: ObservableObject {
  // MARK: - Constants
  static let maxDuration: TimeInterval = 15.0
  
  // MARK: - Published Properties
  @Published var text: String
  @Published var isRecording: Bool = false
  @Published var recordingDuration: TimeInterval = 0
  @Published var progress: Double = 0.0  // 0.0 to 1.0
  @Published var isPlaying: Bool = false
  @Published var hasRecording: Bool = false
  
  // MARK: - Private Properties
  private let audioService = AudioService.shared
  private var cancellables = Set<AnyCancellable>()
  private var existingAudioFileName: String?
  private var tempAudioURL: URL?
  
  // MARK: - Computed Properties
  
  /// Remaining time in the 15-second limit
  var remainingTime: TimeInterval {
    max(Self.maxDuration - recordingDuration, 0)
  }
  
  /// Formatted countdown string (e.g., "00:15")
  var countdownText: String {
    let seconds = Int(ceil(remainingTime))
    return String(format: "00:%02d", seconds)
  }
  
  /// Check if text is valid for saving
  var canSave: Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  /// Will save as draft (no audio)
  var willSaveAsDraft: Bool {
    !hasRecording && existingAudioFileName == nil
  }
  
  /// Get the current playable audio URL
  var currentAudioURL: URL? {
    if let tempURL = tempAudioURL {
      return tempURL
    }
    if let savedFileName = existingAudioFileName {
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      return documentsPath.appendingPathComponent(savedFileName)
    }
    return nil
  }
  
  // MARK: - Initializers
  
  init(text: String = "", existingAudioFileName: String? = nil) {
    self.text = text
    self.existingAudioFileName = existingAudioFileName
    self.hasRecording = existingAudioFileName != nil
    
    setupBindings()
  }
  
  private func setupBindings() {
    // Bind to AudioService state
    audioService.$isRecording
      .receive(on: DispatchQueue.main)
      .assign(to: &$isRecording)
    
    audioService.$currentDuration
      .receive(on: DispatchQueue.main)
      .assign(to: &$recordingDuration)
    
    audioService.$progress
      .receive(on: DispatchQueue.main)
      .assign(to: &$progress)
    
    audioService.$isPlaying
      .receive(on: DispatchQueue.main)
      .assign(to: &$isPlaying)
  }
  
  // MARK: - Permissions
  
  func requestPermission(completion: @escaping (Bool) -> Void) {
    audioService.requestPermission(completion: completion)
  }
  
  // MARK: - Recording Controls
  
  func startRecording() {
    guard !isRecording else { return }
    
    // Clear any previous temp recording
    audioService.clearTempRecording()
    tempAudioURL = nil
    
    audioService.startRecording { [weak self] in
      // Called when auto-stopped at 15 seconds
      DispatchQueue.main.async {
        self?.onRecordingComplete()
      }
    }
  }
  
  func stopRecording() {
    guard isRecording else { return }
    audioService.stopRecording()
    onRecordingComplete()
  }
  
  func toggleRecording() {
    if isRecording {
      stopRecording()
    } else {
      startRecording()
    }
  }
  
  private func onRecordingComplete() {
    tempAudioURL = audioService.tempRecordingURL
    hasRecording = tempAudioURL != nil || existingAudioFileName != nil
  }
  
  // MARK: - Playback Controls
  
  func playPreview() {
    guard let url = currentAudioURL else { return }
    audioService.playPreview(url: url)
  }
  
  func stopPreview() {
    audioService.stopPreview()
  }
  
  func togglePlayback() {
    if isPlaying {
      stopPreview()
    } else {
      playPreview()
    }
  }
  
  // MARK: - Save & Cleanup
  
  /// Saves the recorded audio to Documents directory
  /// Returns the filename (not full path) for storage in SwiftData
  func saveAudioToDocuments() -> String? {
    // If we have a new recording, save it
    if tempAudioURL != nil {
      if let existingFileName = existingAudioFileName {
        // Delete old audio file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let oldURL = documentsPath.appendingPathComponent(existingFileName)
        try? FileManager.default.removeItem(at: oldURL)
      }
      
      let newFileName = audioService.saveTempToDocuments()
      tempAudioURL = nil
      existingAudioFileName = newFileName
      return newFileName
    }
    
    // Otherwise return existing audio filename
    return existingAudioFileName
  }
  
  /// Clears any temporary recordings without saving
  func clearTempRecording() {
    audioService.stopPreview()
    audioService.clearTempRecording()
    tempAudioURL = nil
    recordingDuration = 0
    progress = 0
    // Keep hasRecording true if we have existing audio
    hasRecording = existingAudioFileName != nil
  }
  
  /// Called when view is dismissed - cleanup temp files
  func onDismiss() {
    stopPreview()
    if isRecording {
      audioService.stopRecording()
    }
    audioService.clearTempRecording()
  }
}

