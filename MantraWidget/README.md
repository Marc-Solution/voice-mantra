## 🧩 Running the Project Locally (App + Widget)

This project includes a **Widget Extension** that shares data with the main app using an **App Group**.
Because Apple code signing is **developer-specific**, there are a couple of one-time setup steps required when you first pull the project.

### ✅ Prerequisites

* Xcode installed
* An Apple ID signed into Xcode
  (A free Apple ID is enough for simulator and local testing)

---

## 🔧 One-Time Setup After Pulling the Repo

### 1. Select Your Development Team

You must do this for **both targets**:

* Main App target
* Widget Extension target

Steps:

1. Open the project in Xcode
2. Select the **project** in the navigator
3. Go to **Targets → [Target Name] → Signing & Capabilities**
4. Enable **Automatically manage signing**
5. Select **your own Development Team**

Repeat for **each target**.

---

### 2. Recreate the App Group (Required)

App Groups are scoped to the developer team, so each developer must create their own local version.

For **both the app target and the widget target**:

1. Go to **Signing & Capabilities**
2. Remove the existing App Group (if present)
3. Add a new **App Group**
4. Use the following identifier exactly:

```text
group.marcodeb.VoiceMantra.MantraWidget
```

> The string stays the same, but it will be created under **your own Apple team**.

No code changes are required.

---

### 3. Run the App (Not the Widget)

* Select the **main app scheme**
* Run the app on the simulator or a device
* Add the widget from the widget gallery to verify it works

Widgets cannot be run directly.

---

## 🔁 Updating Widget Data

The widget reads shared data from the App Group.
When the app updates the streak value, it should trigger a widget refresh using:

```swift
WidgetCenter.shared.reloadTimelines(ofKind: "MantraWidget")
```

---

## 🧠 Common Issues

* **“No scheme selected”**
  → Select the main app scheme in the toolbar

* **Widget doesn’t appear**
  → Ensure:

  * Both targets use the same App Group
  * Both targets are signed with your team
  * The main app has been run at least once

---

## ℹ️ Notes

* No Apple Developer Team is required for local development
* When a shared developer team is set up later, App Groups and signing can be unified

---