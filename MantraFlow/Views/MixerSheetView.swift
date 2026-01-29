//
//  MixerSheetView.swift
//  MantraFlow
//
//  Audio mixer sheet for adjusting channel volumes during playback.
//

import SwiftUI

// MARK: - Mixer Sheet View

struct MixerSheetView: View {
  @ObservedObject var audioService: AudioService
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      ZStack {
        Color.brandBackground.ignoresSafeArea()
        
        VStack(spacing: 28) {
          MixerHeader()
          MixerSliderStack(audioService: audioService)
          Spacer()
        }
        .padding()
        .padding(.bottom, 80)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") { dismiss() }
            .fontWeight(.semibold)
            .foregroundColor(.brandAccent)
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}

// MARK: - Mixer Header

private struct MixerHeader: View {
  var body: some View {
    VStack(spacing: 8) {
      Text("Audio Mixer")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.brandText)
      
      Text("Adjust the volume levels for each audio channel")
        .font(.caption)
        .foregroundColor(.brandTextSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 40)
  }
}

// MARK: - Mixer Slider Stack

private struct MixerSliderStack: View {
  @ObservedObject var audioService: AudioService
  
  var body: some View {
    VStack(spacing: 22) {
      MixerSlider(
        label: "Voice",
        icon: "waveform",
        color: .brandAccent,
        value: Binding(
          get: { audioService.voiceVolume },
          set: { audioService.setVoiceVolume($0) }
        )
      )
      
      MixerSlider(
        label: "Music",
        icon: "music.note",
        color: .purple,
        value: Binding(
          get: { audioService.musicVolume },
          set: { audioService.setMusicVolume($0) }
        )
      )
      
      MixerSlider(
        label: "Nature",
        icon: "leaf.fill",
        color: .green,
        value: Binding(
          get: { audioService.natureVolume },
          set: { audioService.setNatureVolume($0) }
        )
      )
      
      MixerSlider(
        label: "Binaural",
        icon: "brain.head.profile",
        color: .orange,
        value: Binding(
          get: { audioService.binauralVolume },
          set: { audioService.setBinauralVolume($0) }
        )
      )
    }
    .padding(.horizontal, 24)
  }
}

// MARK: - Mixer Slider

struct MixerSlider: View {
  let label: String
  let icon: String
  let color: Color
  @Binding var value: Float
  
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Label row
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(color)
          .frame(width: 20)
        
        Text(label)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.brandText)
      }
      
      // Slider row with percentage
      HStack(spacing: 12) {
        Slider(value: $value, in: 0...1, step: 0.05)
          .tint(color)
        
        Text("\(Int(value * 100))%")
          .font(.system(size: 13, weight: .medium, design: .rounded))
          .foregroundColor(.brandTextSecondary)
          .frame(width: 44, alignment: .trailing)
          .monospacedDigit()
      }
    }
  }
}

// MARK: - Preview

#Preview {
  MixerSheetView(audioService: .shared)
}

