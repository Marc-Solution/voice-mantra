# Walkthrough: MantraFlow Rename & Configuration

I have completed the full modernization of the project: renaming it to MantraFlow, creating a setup script, and enforcing code standards.

## 1. Renamed [MantraFlow](file:///Users/dev0l/dev/repos/voice-mantra/MantraFlow.xcodeproj)
- **Project File**: `VoiceMantra.xcodeproj` → `MantraFlow.xcodeproj`
- **Source Directory**: `VoiceMantra/` → `MantraFlow/`
- **Target Name**: `VoiceMantra` → `MantraFlow`
- **Scheme**: `VoiceMantra` → `MantraFlow`
- **Bundle ID**: `com.marcodeb.VoiceMantra` → `com.marcodeb.MantraFlow`
- **App Group**: `group.marcodeb.VoiceMantra.MantraWidget` → `group.marcodeb.MantraFlow.MantraWidget`

> [!NOTE]
> Please update your **Provisioning Profiles** or **App ID** in the Apple Developer Portal to match `com.marcodeb.MantraFlow` (or your custom prefix).

## 2. Configuration Script
I created **[configure_project.sh](file:///Users/dev0l/dev/repos/voice-mantra/configure_project.sh)** to simplify setup for your team.

### How to Use
1.  Open Terminal.
2.  Run: `./configure_project.sh`
3.  Enter your **Apple Development Team ID**.
4.  Enter your **Organization Prefix** (e.g., `com.marcodeb`).

The script automatically updates `MantraFlow.xcodeproj/project.pbxproj` with these values, preventing manual errors.

## 3. Code Formatting
- Created **[.editorconfig](file:///Users/dev0l/dev/repos/voice-mantra/.editorconfig)** to strictly enforce 2-space indentation.
- **Reformatted** all 21 Swift files in the repository from 4 spaces to 2 spaces.

## Verification
- **Code**: Verified all Swift files now use 2-space indentation.
- **Config**: Verified `configure_project.sh` correctly updates the project file.
- **Structure**: Verified all internal project references match the new `MantraFlow` naming.
