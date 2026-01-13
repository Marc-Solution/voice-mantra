# Suggested Project Structure

A recommended folder organization for your existing files, following iOS/Swift/SwiftUI best practices.

---

## 📁 Current Files → Suggested Organization

```
VoiceMantra/
│
├── 📱 App/
│   ├── MantraFlowApp.swift
│   ├── Info.plist
│   └── VoiceMantra.entitlements
│
├── 🎨 Resources/
│   ├── Assets.xcassets/
│   │
│   └── Audio/
│       ├── AmbientMusic.mp3
│       ├── NatureSounds.mp3
│       └── Bineural5Hz.mp3
│
├── 🗂️ Models/
│   └── Models.swift
│
├── 👁️ Views/
│   ├── HomeView.swift
│   ├── CreateListView.swift
│   ├── ListDetailView.swift
│   ├── AffirmationEditorView.swift
│   ├── PlayerView.swift
│   ├── MixerSheetView.swift
│   ├── SettingsView.swift
│   └── StreakToastView.swift
│
├── 🧠 ViewModels/
│   ├── AffirmationEditorViewModel.swift
│   └── PlayerViewModel.swift
│
├── ⚙️ Services/
│   ├── AudioService.swift
│   └── NotificationManager.swift
│
├── 📊 Managers/
│   └── StreakManager.swift
│
└── 🎨 Extensions/
    └── Color+Theme.swift
```

---

## � File Mapping Summary

| Current Location | Suggested Folder | Files |
|------------------|------------------|-------|
| Root | **App/** | `MantraFlowApp.swift`, `Info.plist`, `VoiceMantra.entitlements` |
| Root | **Resources/** | `Assets.xcassets/` |
| Root | **Resources/Audio/** | `AmbientMusic.mp3`, `NatureSounds.mp3`, `Bineural5Hz.mp3` |
| Root | **Models/** | `Models.swift` |
| Root | **Views/** | `HomeView.swift`, `CreateListView.swift`, `ListDetailView.swift`, `AffirmationEditorView.swift`, `PlayerView.swift`, `MixerSheetView.swift`, `SettingsView.swift`, `StreakToastView.swift` |
| Root | **ViewModels/** | `AffirmationEditorViewModel.swift`, `PlayerViewModel.swift` |
| Root | **Services/** | `AudioService.swift`, `NotificationManager.swift` |
| Root | **Managers/** | `StreakManager.swift` |
| Root | **Extensions/** | `Color+Theme.swift` |

---

## 🏛️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Views/                               │
│  (SwiftUI Views - UI presentation)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      ViewModels/                             │
│  (@Observable - State management & logic)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               Services/ & Managers/                          │
│  (Business logic, audio, notifications, persistence)         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Models/                               │
│  (SwiftData entities & data structures)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## � Folder Descriptions

| Folder | Purpose |
|--------|---------|
| **App/** | Application entry point, configuration, and entitlements |
| **Resources/** | Static assets: images, colors, and audio files |
| **Models/** | SwiftData entities and data structures |
| **Views/** | All SwiftUI views |
| **ViewModels/** | View state management and business logic |
| **Services/** | External operations: audio playback, notifications |
| **Managers/** | Singletons for app-wide state (streaks, stats) |
| **Extensions/** | Swift type extensions and theme definitions |

---

<p align="center">
  <i>Organizing files into logical folders improves maintainability and navigation.</i> 📂
</p>
