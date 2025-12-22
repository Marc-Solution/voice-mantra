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
    
    // MARK: - Focus Management
    @FocusState private var isTextFieldFocused: Bool
    
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
            ZStack {
                // Brand background - tappable to dismiss keyboard
                Color.brandBackground
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Text Input Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Affirmation")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.brandTextSecondary)
                            
                            TextField("I am confident, capable, and strong...", text: $vm.text, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .foregroundColor(.brandText)
                                .lineLimit(4...8)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.brandField)
                                )
                                .focused($isTextFieldFocused)
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
                                            .fill(Color.brandField)
                                            .frame(height: 8)
                                        
                                        // Progress fill
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.brandAccent, Color.brandAccent.opacity(0.7)],
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
                                    .foregroundColor(vm.isRecording ? .red : .brandText)
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
                                    isTextFieldFocused = false
                                    requestPermissionAndToggle()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(vm.isRecording ? Color.red : Color.brandAccent)
                                            .frame(width: 80, height: 80)
                                            .shadow(color: (vm.isRecording ? Color.red : Color.brandAccent).opacity(0.4), radius: 8, x: 0, y: 4)
                                        
                                        if vm.isRecording {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.black)
                                                .frame(width: 28, height: 28)
                                        } else {
                                            Circle()
                                                .fill(Color.black)
                                                .frame(width: 28, height: 28)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(vm.isPlaying)
                                
                                // Play/Preview Button (appears after recording)
                                Button(action: {
                                    isTextFieldFocused = false
                                    vm.togglePlayback()
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.brandField)
                                            .frame(width: 56, height: 56)
                                        
                                        Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                  .font(.system(size: 22))
                                            .foregroundColor(vm.hasRecording ? .brandAccent : .brandTextSecondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!vm.hasRecording || vm.isRecording)
                                .opacity(vm.hasRecording ? 1 : 0.4)
                            }
                            
                            // Recording Status Text
                            Text(statusText)
                .font(.subheadline)
                .foregroundColor(.brandTextSecondary)
                                .frame(height: 20)
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.brandField)
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
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(vm.canSave ? Color.brandAccent : Color.brandAccent.opacity(0.4))
                                )
                            }
                            .disabled(!vm.canSave || vm.isRecording)
                            
                            if vm.willSaveAsDraft && vm.canSave {
                                Text("No audio recorded. This will be saved as a draft.")
                .font(.caption)
                                    .foregroundColor(.brandTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(existingAffirmation == nil ? "New Affirmation" : "Edit Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button in navigation bar
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.onDismiss()
                        dismiss()
                    }
                    .foregroundColor(.brandAccent)
                }
                
                // Done button above keyboard
                ToolbarItemGroup(placement: .keyboard) {
              Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                    .foregroundColor(.brandAccent)
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
        // Dismiss keyboard first
        isTextFieldFocused = false
        
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
            .fill(isActive ? Color.brandAccent : Color.brandField)
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
