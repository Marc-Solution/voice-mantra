//
//  PlayerView.swift
//  MantraFlow
//
//  Main playback screen for affirmation sessions.
//  Follows Apple's 2026 MVVM architecture with @Observable.
//

import SwiftUI
import SwiftData

// MARK: - Navigation Destination

/// Type-safe navigation wrapper for PlayerView
struct PlayerDestination: Hashable {
  let listId: PersistentIdentifier
 let list: AffirmationList
  
  init(list: AffirmationList) {
    self.listId = list.persistentModelID
    self.list = list
  }
  
  static func == (lhs: PlayerDestination, rhs: PlayerDestination) -> Bool {
    lhs.listId == rhs.listId
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(listId)
  }
}

// MARK: - Player View

struct PlayerView: View {
 @Environment(\.dismiss) private var dismiss
  @State private var viewModel: PlayerViewModel
  
  init(list: AffirmationList) {
    _viewModel = State(initialValue: PlayerViewModel(list: list))
  }
  
  var body: some View {
    ZStack {
      BackgroundGradient()
      VStack(spacing: 0) {
        ProgressIndicator(viewModel: viewModel)
        Spacer()
        AffirmationDisplay(viewModel: viewModel)
        Spacer()
        PlaybackControls(viewModel: viewModel)
      }
      .padding()
    }
    .navigationTitle("Now Playing: \(viewModel.list.title)")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(Color.brandBackground, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .sheet(isPresented: $viewModel.isShowingMixer) {
      MixerSheetView(audioService: viewModel.audioService)
    }
    .onAppear(perform: viewModel.onViewAppear)
    .onDisappear(perform: viewModel.onViewDisappear)
    .streakToast(isShowing: $viewModel.isShowingStreakToast, streakCount: viewModel.currentStreak)
  }
}

// MARK: - Subviews

private struct BackgroundGradient: View {
 var body: some View {
   LinearGradient(
      colors: [Color.brandBackground, Color.brandBackground.opacity(0.95)],
    startPoint: .top,
    endPoint: .bottom
   )
   .ignoresSafeArea()
  }
}

private struct ProgressIndicator: View {
  let viewModel: PlayerViewModel
   
  var body: some View {
        VStack {
      if viewModel.hasPlayableContent {
            HStack(spacing: 6) {
          Text(viewModel.progressText)
                .font(.caption)
                .fontWeight(.medium)
          if viewModel.isActive {
                Circle()
              .fill(viewModel.playbackState == .playing ? Color.brandAccent : Color.brandAccent.opacity(0.6))
                  .frame(width: 5, height: 5)
              }
            }
            .foregroundColor(.brandTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.brandField.opacity(0.8))
            .cornerRadius(12)
          }
        }
    .frame(height: 60)
        .padding(.top, 20)
  }
}
        
private struct AffirmationDisplay: View {
  let viewModel: PlayerViewModel
        
  var body: some View {
        ZStack {
      // Invisible placeholder to maintain consistent height
          Text(" ")
            .font(.system(size: 32, weight: .regular, design: .serif))
            .opacity(0)
            .frame(minHeight: 120)
          
      if viewModel.playbackState != .pauseBetween {
        if let affirmation = viewModel.currentAffirmation {
              Text(affirmation.text)
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundColor(.brandText)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, 28)
                .transition(.opacity)
        } else if !viewModel.hasPlayableContent {
              Text("No recorded affirmations")
                .font(.title2)
                .foregroundColor(.brandTextSecondary)
            }
          }
        }
        .frame(maxWidth: .infinity)
    .animation(.easeInOut(duration: 0.4), value: viewModel.playbackState)
    .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
  }
}

private struct PlaybackControls: View {
  let viewModel: PlayerViewModel
  
  var body: some View {
    VStack(spacing: 28) {
      MixerButton(action: viewModel.showMixer)
      PlayStopButton(viewModel: viewModel)
    }
    .padding(.bottom, 50)
  }
}

private struct MixerButton: View {
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .fill(Color.brandField)
          .frame(width: 56, height: 56)
        Circle()
          .strokeBorder(Color.brandAccent.opacity(0.2), lineWidth: 1)
          .frame(width: 56, height: 56)
        Image(systemName: "slider.horizontal.3")
          .font(.system(size: 22, weight: .medium))
          .foregroundColor(.brandAccent)
      }
    }
  }
}

private struct PlayStopButton: View {
  let viewModel: PlayerViewModel
  private let ringSize: CGFloat = 108
  private let ringLineWidth: CGFloat = 5
  private let buttonSize: CGFloat = 84
  
  /// Animation duration matches timer interval (0.05s = 20 FPS) for perfectly smooth motion
  private let progressAnimationDuration: Double = 0.05
  
  var body: some View {
    ZStack {
      // Background track ring
      Circle()
        .stroke(Color.brandField, lineWidth: ringLineWidth)
        .frame(width: ringSize, height: ringSize)
      
      // Animated progress ring - glides smoothly like a clock hand
      Circle()
        .trim(from: 0, to: viewModel.macroProgress)
        .stroke(Color.brandAccent, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
        .frame(width: ringSize, height: ringSize)
        .rotationEffect(.degrees(-90))
        .animation(.linear(duration: progressAnimationDuration), value: viewModel.macroProgress)
      
      // Play/Stop button
      Button(action: viewModel.togglePlayback) {
        Image(systemName: viewModel.isActive ? "stop.circle.fill" : "play.circle.fill")
          .font(.system(size: buttonSize))
          .foregroundColor(viewModel.hasPlayableContent ? .brandAccent : .brandTextSecondary)
          .shadow(color: Color.brandAccent.opacity(viewModel.isActive ? 0.3 : 0.15), radius: 10, x: 0, y: 4)
      }
      .disabled(!viewModel.hasPlayableContent)
    }
    .scaleEffect(viewModel.isActive ? 1.03 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: viewModel.isActive)
  }
}

// MARK: - Preview

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: AffirmationList.self, Affirmation.self, configurations: config)
  let sampleList = AffirmationList(title: "Morning Affirmations")
  
  return NavigationStack {
    PlayerView(list: sampleList)
  }
  .modelContainer(container)
}
