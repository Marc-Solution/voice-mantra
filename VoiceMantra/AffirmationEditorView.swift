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
    
    init(list: AffirmationList, existingAffirmation: Affirmation? = nil) {
        self.list = list
        self.existingAffirmation = existingAffirmation
        
        let initialText = existingAffirmation?.text ?? ""
        let existingAudioFileName = existingAffirmation?.audioFileName
        _vm = StateObject(wrappedValue: AffirmationEditorViewModel(
            text: initialText,
            existingAudioFileName: existingAudioFileName
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Text Input Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Affirmation")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        TextField("I am confident, capable, and strong...", text: $vm.text, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .lineLimit(4...8)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Recording Section
                    VStack(spacing: 20) {
                        // Waveform Visualization Area
                        WaveformView(isRecording: vm.isRecording, isPlaying: vm.isPlaying)
                            .frame(height: 80)
                            .padding(.horizontal)
                        
                        // Progress Bar
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(UIColor.systemGray5))
                                        .frame(height: 8)
                                    
                                    // Progress fill
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * vm.progress, height: 8)
                                        .animation(.linear(duration: 0.1), value: vm.progress)
                                }
                            }
                            .frame(height: 8)
                            .padding(.horizontal)
                            
                            // Timer Display
                            Text(vm.countdownText)
                                .font(.system(size: 48, weight: .light, design: .monospaced))
                                .foregroundColor(vm.isRecording ? .red : .primary)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.1), value: vm.countdownText)
                        }
                        
                        // Control Buttons
                        HStack(spacing: 32) {
                            // Spacer for balance
                            Color.clear
                                .frame(width: 56, height: 56)
                            
                            // Main Record/Stop Button
                            Button(action: {
                                requestPermissionAndToggle()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(vm.isRecording ? Color.red : Color.blue)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: (vm.isRecording ? Color.red : Color.blue).opacity(0.4), radius: 8, x: 0, y: 4)
                                    
                                    if vm.isRecording {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white)
                                            .frame(width: 28, height: 28)
                                    } else {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 28, height: 28)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(vm.isPlaying)
                            
                            // Play/Preview Button (appears after recording)
                            Button(action: {
                                vm.togglePlayback()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .frame(width: 56, height: 56)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(vm.hasRecording ? .blue : .gray)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!vm.hasRecording || vm.isRecording)
                            .opacity(vm.hasRecording ? 1 : 0.4)
                        }
                        
                        // Recording Status Text
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(height: 20)
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    // MARK: - Save Section
                    VStack(spacing: 12) {
                        Button(action: save) {
                            HStack {
                                if vm.willSaveAsDraft {
                                    Image(systemName: "doc.text")
                                    Text("Save as Draft")
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Affirmation")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(vm.canSave ? Color.blue : Color.gray)
                            )
                        }
                        .disabled(!vm.canSave || vm.isRecording)
                        
                        if vm.willSaveAsDraft && vm.canSave {
                            Text("No audio recorded. This will be saved as a draft.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(existingAffirmation == nil ? "New Affirmation" : "Edit Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.onDismiss()
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(vm.isRecording)
        }
        .onDisappear {
            vm.onDismiss()
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        if vm.isRecording {
            return "Recording..."
        } else if vm.isPlaying {
            return "Playing preview..."
        } else if vm.hasRecording {
            return "Recording ready"
        } else {
            return "Tap to record"
        }
    }
    
    // MARK: - Actions
    
    private func requestPermissionAndToggle() {
        vm.requestPermission { granted in
            if granted {
                if vm.isPlaying {
                    vm.stopPreview()
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
        
        // Save audio to Documents directory if there's a recording
        let audioFileName = vm.saveAudioToDocuments()
        
        if let existing = existingAffirmation {
            // EDITING: Update text, optionally update audio
            existing.text = trimmedText
            if vm.hasRecording {
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
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save affirmation: \(error)")
        }
        
        dismiss()
    }
}

// MARK: - Waveform Visualization

struct WaveformView: View {
    let isRecording: Bool
    let isPlaying: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    private let barCount = 40
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        index: index,
                        totalBars: barCount,
                        isActive: isRecording || isPlaying,
                        animationPhase: animationPhase
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }
}

struct WaveformBar: View {
    let index: Int
    let totalBars: Int
    let isActive: Bool
    let animationPhase: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isActive ? Color.blue : Color(UIColor.systemGray4))
            .frame(width: 4, height: barHeight)
            .animation(.easeInOut(duration: 0.15), value: isActive)
    }
    
    private var barHeight: CGFloat {
        if isActive {
            // Animated wave pattern
            let normalizedIndex = CGFloat(index) / CGFloat(totalBars)
            let wave = sin((normalizedIndex + animationPhase) * .pi * 4)
            let randomFactor = CGFloat.random(in: 0.5...1.0)
            return 20 + (wave * 25 * randomFactor)
        } else {
            // Static subtle wave
            let normalizedIndex = CGFloat(index) / CGFloat(totalBars)
            let wave = sin(normalizedIndex * .pi * 2)
            return 15 + (wave * 8)
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: AffirmationList.self, Affirmation.self, configurations: config)
    let sampleList = AffirmationList(title: "Sample List")
    
    return AffirmationEditorView(list: sampleList)
        .modelContainer(container)
}
