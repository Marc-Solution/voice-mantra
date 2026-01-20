//
//  SettingsView.swift
//  MantraFlow
//
//  Settings screen for app preferences and reminders
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Reflection Settings
    @AppStorage("reflectionPause") private var reflectionPause: Int = 10
    
    // MARK: - Reminder Settings
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled: Bool = false
    @AppStorage("dailyReminderTime") private var dailyReminderTimeInterval: Double = 28800 // Default: 8:00 AM (8 * 3600)
    
    @StateObject private var notificationManager = NotificationManager.shared
    
    /// Computed property to convert stored interval to Date for DatePicker
    private var reminderTime: Date {
        get {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            return startOfDay.addingTimeInterval(dailyReminderTimeInterval)
        }
    }
    
    /// Available reflection pause options in seconds
    private let reflectionOptions = [5, 10, 15, 30]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Brand background
                Color.brandBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Reflection Section
                        settingsSection(title: "Playback") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "pause.circle")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.brandAccent)
                                    
                                    Text("Reflection Pause")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.brandText)
                                    
                                    Spacer()
                                }
                                
                                Text("Duration of silence between affirmations")
                                    .font(.caption)
                                    .foregroundColor(.brandTextSecondary)
                                
                                Picker("Reflection Pause", selection: $reflectionPause) {
                                    ForEach(reflectionOptions, id: \.self) { seconds in
                                        Text("\(seconds)s").tag(seconds)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .tint(.brandAccent)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.brandField)
                            )
                        }
                        
                        // MARK: - Reminders Section
                        settingsSection(title: "Reminders") {
                            VStack(spacing: 16) {
                                // Toggle row
                                HStack {
                                    Image(systemName: "bell.badge")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.brandAccent)
                                    
                                    Text("Daily Reminder")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.brandText)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $dailyReminderEnabled)
                                        .tint(.brandAccent)
                                        .labelsHidden()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.brandField)
                                )
                                .onChange(of: dailyReminderEnabled) { _, newValue in
                                    handleReminderToggle(enabled: newValue)
                                }
                                
                                // Time picker (only visible when enabled)
                                if dailyReminderEnabled {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "clock")
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundColor(.brandAccent)
                                            
                                            Text("Reminder Time")
                                                .font(.body.weight(.medium))
                                                .foregroundColor(.brandText)
                                            
                                            Spacer()
                                            
                                            DatePicker(
                                                "",
                                                selection: Binding(
                                                    get: { reminderTime },
                                                    set: { updateReminderTime($0) }
                                                ),
                                                displayedComponents: .hourAndMinute
                                            )
                                            .labelsHidden()
                                            .tint(.brandAccent)
                                            .colorScheme(.dark)
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.brandField)
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: dailyReminderEnabled)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.brandBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.brandAccent)
                }
            }
        }
    }
    
    // MARK: - Section Builder
    
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.brandTextSecondary)
                .padding(.horizontal, 4)
            
            content()
        }
    }
    
    // MARK: - Reminder Logic
    
    /// Handles the reminder toggle change
    private func handleReminderToggle(enabled: Bool) {
        if enabled {
            // Request notification permission and schedule
            Task {
                let granted = await notificationManager.requestPermission()
                if granted {
                    notificationManager.scheduleDailyReminder(at: reminderTime)
                } else {
                    // Permission denied - turn off toggle
                    await MainActor.run {
                        dailyReminderEnabled = false
                    }
                }
            }
        } else {
            // Cancel all reminders
            notificationManager.cancelAllReminders()
        }
    }
    
    /// Updates the reminder time and reschedules notification
    private func updateReminderTime(_ newTime: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let interval = newTime.timeIntervalSince(startOfDay)
        dailyReminderTimeInterval = interval
        
        // Reschedule if enabled
        if dailyReminderEnabled {
            notificationManager.scheduleDailyReminder(at: newTime)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

