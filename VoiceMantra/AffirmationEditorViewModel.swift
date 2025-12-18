import Foundation
import AVFoundation
import Combine
import SwiftUI

final class AffirmationEditorViewModel: ObservableObject {
  // MARK: - Published Properties (required by AffirmationEditorView)
  @Published var transcript: String
  @Published var isRecording: Bool = false
  @Published var recordingDuration: TimeInterval = 0
  @Published var audioURL: URL?

  // MARK: - Private Properties
  private var audioRecorder: AVAudioRecorder?
  private var timer: Timer?
  private var startDate: Date?
  private var cancellable: AnyCancellable?

  // MARK: - Initializers
  init(transcript: String = "") {
    self.transcript = transcript

    // Subscribe to AudioService duration updates (optional integration)
    cancellable = AudioService.shared.$currentDuration
      .sink { [weak self] duration in
        // Only update if we're using AudioService for recording
        if self?.audioRecorder == nil && duration > 0 {
          self?.recordingDuration = duration
        }
      }
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

      let url = Self.makeRecordingURL()
      let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]

      audioRecorder = try AVAudioRecorder(url: url, settings: settings)
      audioRecorder?.prepareToRecord()
      audioRecorder?.record()

      audioURL = url
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
  private static func makeRecordingURL() -> URL {
    let fm = FileManager.default
    let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let filename = "affirmation-\(UUID().uuidString).m4a"
    return docs.appendingPathComponent(filename)
  }

  /// Simple export helper: return Data for the audio URL
  func audioData() -> Data? {
    guard let url = audioURL else { return nil }
    return try? Data(contentsOf: url)
  }
}

