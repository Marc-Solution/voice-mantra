import SwiftUI
import AVFoundation

struct AffirmationEditorView: View {
  @StateObject var vm: AffirmationEditorViewModel
  @Environment(\.presentationMode) var presentationMode

  // Hook this closure up to your store/save method
  var saveAction: ((_ transcript: String, _ audioURL: URL?, _ duration: TimeInterval) -> Void)?

  // Custom initializer required for @StateObject with external values
  init(vm: AffirmationEditorViewModel, saveAction: ((_ transcript: String, _ audioURL: URL?, _ duration: TimeInterval) -> Void)? = nil) {
    _vm = StateObject(wrappedValue: vm)
    self.saveAction = saveAction
  }

  var body: some View {
    NavigationView {
      Form {
        Section() {
          TextEditor(text: $vm.transcript)
            .frame(minHeight: 140)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(UIColor.separator)))
            
        }

        Section(header: Text("Recording")) {
          HStack {
            Button(action: askThenToggle) {
              HStack {
                Image(systemName: vm.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                  .font(.system(size: 22))
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
          if let url = vm.audioURL {
            HStack {
              Text(url.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
              Spacer()
              Button("Play") {
                playFile(url)
              }
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
        }
      }
      .navigationTitle("Add/Edit Affirmation")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { presentationMode.wrappedValue.dismiss() }
        }
      }
    }
  }

  // MARK: - Actions
  private func askThenToggle() {
    // Request mic permission if needed, then toggle
    vm.requestPermission { granted in
      if granted {
        vm.toggleRecording()
      } else {
        // show a simple alert — but in this quick view we just print
        print("Microphone permission denied")
      }
    }
  }

  private func save() {
    saveAction?(vm.transcript, vm.audioURL, vm.recordingDuration)
    presentationMode.wrappedValue.dismiss()
  }

  private func playFile(_ url: URL) {
    // Simple AVPlayer playback
    let player = AVPlayer(url: url)
    player.play()
    // Note: player will go out of scope quickly; for production hold reference in vm
  }

  // MARK: - Helpers
  private func formatTime(_ t: TimeInterval) -> String {
    let int = Int(round(t))
    let m = int / 60
    let s = int % 60
    return String(format: "%02d:%02d", m, s)
  }
}

struct AffirmationEditorView_Previews: PreviewProvider {
  static var previews: some View {
    AffirmationEditorView(vm: AffirmationEditorViewModel(transcript: "Write your affirmation"))
  }
}

