# MantraWidget Setup & Streak Syncing

This widget is designed to display the user's current mantra streak. However, for the widget to share data with the main application, **App Groups** must be configured.

## ⚠️ Important: Development Team & App Groups

App Groups (and Bundle Identifiers) are globally unique and tied to a specific Apple Developer Team. 
Because of this, the App Group configuration cannot be shared directly in the repository without causing signing errors for other developers (since they cannot sign with the original creator's Team ID).

### Current State
The code currently uses standard `UserDefaults` or placeholder data to ensure the project builds and runs for everyone out of the box.

### How to Enable Streak Syncing (Local Setup)

If you want to run the app on a device/simulator and see the real streak data in the widget, follow these steps:

1. **Configure App Groups in Xcode**:
   - Go to **Project Settings** -> Select **VoiceMantra** (Main Target) -> **Signing & Capabilities**.
   - Click `+ Capability` and add **App Groups**.
   - Create a new group (e.g., `group.com.yourname.voicemantra`).
   - Repeat this for the **MantraWidgetExtension** target, selecting the **same** group.

2. **Update `StreakManager.swift`**:
   - Change `defaults` to use the App Group:
     ```swift
     private var defaults: UserDefaults {
         UserDefaults(suiteName: "group.com.yourname.voicemantra") ?? .standard
     }
     ```
   - Import `WidgetKit` and add reload logic to `save()`:
     ```swift
     import WidgetKit
     // ... inside save() ...
     WidgetCenter.shared.reloadAllTimelines()
     ```

3. **Update `MantraWidget.swift`**:
   - In `timeline()`, read from the App Group:
     ```swift
     let defaults = UserDefaults(suiteName: "group.com.yourname.voicemantra")
     let streak = defaults?.integer(forKey: "mantraflow_current_streak") ?? 0
     let entry = SimpleEntry(date: Date(), configuration: configuration, streak: streak)
     ```
   - Update `SimpleEntry` to include `let streak: Int`.

4. **Run the App**:
   - Build and run. The app will now write to the shared container, and the widget will read from it.

> **Note**: Do not commit your personal App Group ID or Bundle ID changes to the shared repository unless you are the repository owner.
