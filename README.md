# Voice Mantra

A beautifully designed iOS app for recording, managing, and playing personal affirmations with immersive audio experiences.

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

### 🎙️ Personal Affirmation Recording
- **Record your own voice** - Create personalized affirmations with your own voice recordings (up to 15 seconds each)
- **Organize into lists** - Group affirmations into themed lists (e.g., "Morning Motivation", "Confidence Boost")
- **Easy management** - Edit, reorder, mute, or delete affirmations with intuitive controls

### 🎧 Immersive Playback Experience
- **Continuous loop playback** - Listen to your affirmations on repeat with configurable pause intervals
- **4-Channel Audio Mixer** - Blend your voice recordings with:
  - 🎵 Ambient background music
  - 🌿 Soothing nature sounds
  - 🧠 5Hz Theta binaural beats (for deep relaxation)
- **Background audio support** - Keep listening even when the screen is locked or other apps are in use
- **Reflection pauses** - Configurable gaps between affirmations (5, 10, 15, or 30 seconds)

### 📊 Progress Tracking
- **Streak tracking** - Build and maintain daily practice streaks
- **Total time logged** - Track your cumulative listening time
- **Visual progress** - Beautiful progress ring during playback sessions

### 🔔 Daily Reminders
- **Push notifications** - Set customizable daily reminders to practice
- **Flexible scheduling** - Choose your preferred reminder time

### 🎨 Premium Dark Mode UI
- **Elegant dark theme** - Easy on the eyes for morning and evening sessions
- **Smooth animations** - Polished micro-interactions throughout the app
- **Modern design** - Clean, minimalist interface with brand accent colors

## 📱 Screenshots

*Coming soon*

## 🛠️ Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Native data persistence
- **AVFoundation** - Audio recording and multi-track playback
- **MVVM Architecture** - Clean separation of concerns with `@Observable`
- **UserNotifications** - Push notification scheduling

## 📋 Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 🚀 Getting Started

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/voice-mantra.git
   cd voice-mantra
   ```

2. **Open in Xcode**
   ```bash
   open MantraFlow.xcodeproj
   ```

3. **Build and run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### First Steps

1. Tap **Create List** to make your first affirmation list
2. Add affirmations by typing text and recording your voice
3. Press the **Play** button to start your session
4. Use the **Mixer** to customize your background audio blend
5. Build your streak by practicing daily!

## 🏗️ Project Structure

```
MantraFlow/
├── MantraFlowApp.swift      # App entry point & configuration
├── Models.swift             # SwiftData models (AffirmationList, Affirmation)
├── HomeView.swift           # Main list view with stats
├── CreateListView.swift     # New list creation
├── ListDetailView.swift     # Edit affirmations in a list
├── AffirmationEditorView.swift  # Recording & editing UI
├── PlayerView.swift         # Playback screen
├── PlayerViewModel.swift    # Playback logic
├── MixerSheetView.swift     # 4-channel audio mixer
├── SettingsView.swift       # App preferences
├── AudioService.swift       # Recording & playback engine
├── StreakManager.swift      # Streak & stats tracking
├── NotificationManager.swift # Daily reminder scheduling
└── Color+Theme.swift        # Brand color system
```

## 🎵 Included Audio Assets

The app includes three royalty-free audio tracks for the background mixer:
- `AmbientMusic.mp3` - Calm ambient background music
- `NatureSounds.mp3` - Relaxing nature soundscape
- `Bineural5Hz.mp3` - 5Hz Theta binaural beats

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Marco Deb** - *Initial work* - 2025

---

<p align="center">
  <i>Build your confidence, one affirmation at a time.</i> 🌟
</p>
