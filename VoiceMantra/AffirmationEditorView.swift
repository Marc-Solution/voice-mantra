import SwiftUI
import SwiftData
import AVFoundation

struct AffirmationEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject var vm: AffirmationEditorViewModel
    
    /// The list to add the affirmation to
    let list: AffirmationList
    
    /// Optional existing affirmation being edited (nil for new affirmation)
    var existingAffirmation: Affirmation?
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    init(list: AffirmationList, existingAffirmation: Affirmation? = nil) {
        self.list = list
        self.existingAffirmation = existingAffirmation
        
        // Initialize view model with existing data if editing
        let initialText = existingAffirmation?.text ?? ""
        let existingAudioFileName = existingAffirmation?.audioFileName
        _vm = StateObject(wrappedValue: AffirmationEditorViewModel(
            text: initialText,
            existingAudioFileName: existingAudioFileName
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Affirmation Text")) {
                    TextEditor(text: $vm.text)
                        .frame(minHeight: 140)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(UIColor.separator)))
                }
                
                Section(header: Text("Recording")) {
                    HStack {
                        Button(action: askThenToggle) {
                            HStack {
                                Image(systemName: vm.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(vm.isRecording ? .red : .blue)
                                Text(vm.isRecording ? "Stop" : "Record")
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        Spacer()
                        if vm.recordingDuration > 0 {
                            Text(formatTime(vm.recordingDuration))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if vm.hasAudio {
                        HStack {
                            if let url = vm.currentAudioURL {
                                Text(url.lastPathComponent)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: togglePlayback) {
                                HStack(spacing: 4) {
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    Text(isPlaying ? "Pause" : "Play")
                                }
                                .font(.subheadline)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    } else {
                        Text("No recording yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            Text("Save")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(vm.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(existingAffirmation == nil ? "New Affirmation" : "Edit Affirmation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.clearTempRecording()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    // MARK: - Actions
    private func askThenToggle() {
        vm.requestPermission { granted in
            if granted {
                // Stop playback if recording
                if !vm.isRecording {
                    stopPlayback()
                }
                vm.toggleRecording()
            } else {
                print("Microphone permission denied")
            }
        }
    }
    
    private func save() {
        let trimmedText = vm.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Save audio to Documents directory if there's a new recording
        let audioFileName = vm.saveAudioToDocuments()
        
        if let existing = existingAffirmation {
            // EDITING: Only update the text property, keep audio linked
            existing.text = trimmedText
            // Only update audio if a new one was recorded
            if vm.tempAudioURL != nil || audioFileName != existing.audioFileName {
                existing.audioFileName = audioFileName
            }
        } else {
            // CREATING: Create new Affirmation and add to list
            let newAffirmation = Affirmation(
                text: trimmedText,
                audioFileName: audioFileName,
                list: list
            )
            modelContext.insert(newAffirmation)
            list.affirmations.append(newAffirmation)
        }
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save affirmation: \(error)")
        }
        
        dismiss()
    }
    
    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        guard let url = vm.currentAudioURL else { return }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = AudioPlayerDelegate.shared
            AudioPlayerDelegate.shared.onFinish = { [self] in
                DispatchQueue.main.async {
                    self.isPlaying = false
                }
            }
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
    
    // MARK: - Helpers
    private func formatTime(_ t: TimeInterval) -> String {
        let int = Int(round(t))
        let m = int / 60
        let s = int % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Audio Player Delegate
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerDelegate()
    var onFinish: (() -> Void)?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AffirmationList.self, Affirmation.self, configurations: config)
    let sampleList = AffirmationList(title: "Sample List")
    
    return AffirmationEditorView(list: sampleList)
        .modelContainer(container)
}
