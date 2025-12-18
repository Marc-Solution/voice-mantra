//
//  AudioService.swift
//  Appformations
//
//  Created by Marco Deb on 2025-12-11.
//

import Foundation
import AVFoundation
import Combine

/// Simple wrapper around AVAudioRecorder for AppFirmations
final class AudioService: NSObject, ObservableObject, AVAudioRecorderDelegate {
  static let shared = AudioService()

  private var recorder: AVAudioRecorder?
  private var recordingSession: AVAudioSession?
  private var timer: Timer?
  @Published var currentDuration: TimeInterval = 0

  private override init() {
    super.init()
    recordingSession = AVAudioSession.sharedInstance()
  }

  // MARK: - Permissions

  func requestPermission(completion: @escaping (Bool) -> Void) {
    AVAudioApplication.requestRecordPermission { granted in
      DispatchQueue.main.async { completion(granted) }
    }
  }

  // MARK: - Start Recording

  func startRecording(completion: @escaping (URL?) -> Void) {
    requestPermission { [weak self] granted in
      guard let self = self, granted else {
        print("❌ Microphone permission denied")
        completion(nil)
        return
      }

      do {
        try self.recordingSession?.setCategory(.playAndRecord, mode: .default)
        try self.recordingSession?.setActive(true)

        let fileURL = Self.createTempFile()
        let settings: [String: Any] = [
          AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
          AVSampleRateKey: 12000,
          AVNumberOfChannelsKey: 1,
          AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        self.recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        self.recorder?.delegate = self
        self.recorder?.record()

        self.startTimer()
        print("🎙️ Recording started at: \(fileURL.lastPathComponent)")
        completion(fileURL)

      } catch {
        print("❌ Failed to start recording:", error)
        completion(nil)
      }
    }
  }

  // MARK: - Stop Recording

  func stopRecording() -> URL? {
    recorder?.stop()
    stopTimer()
    let url = recorder?.url
    recorder = nil
    currentDuration = 0
    print("🛑 Recording stopped")
    return url
  }

  // MARK: - Utilities

  private static func createTempFile() -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let filename = "affirmation-\(UUID().uuidString).m4a"
    return tempDir.appendingPathComponent(filename)
  }

  private func startTimer() {
    stopTimer()
    currentDuration = 0
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      self.currentDuration = self.recorder?.currentTime ?? 0
    }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  // MARK: - AVAudioRecorderDelegate (optional)

  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    if let error = error {
      print("⚠️ Recorder encode error:", error.localizedDescription)
    }
  }
}

