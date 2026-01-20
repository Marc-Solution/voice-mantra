//
//  NotificationManager.swift
//  MantraFlow
//
//  Handles local notification scheduling for daily reminders
//

import Foundation
import Combine
import UserNotifications

/// Singleton manager for local notification scheduling
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderIdentifier = "daily-mantra-reminder"
    
    @Published var isAuthorized: Bool = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Checks current notification authorization status
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Requests permission to send notifications
    /// - Returns: True if permission was granted
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("❌ Notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedules a daily reminder at the specified time
    /// - Parameter time: The time of day to send the reminder
    func scheduleDailyReminder(at time: Date) {
        // Cancel any existing reminders first
        cancelAllReminders()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "MantraFlow"
        content.body = "Time for your daily flow. Ready for your affirmations? ✨"
        content.sound = .default
        
        // Extract hour and minute from the provided time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Create a daily trigger at the specified time
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                let hour = components.hour ?? 0
                let minute = components.minute ?? 0
                print("✅ Daily reminder scheduled for \(String(format: "%02d:%02d", hour, minute))")
            }
        }
    }
    
    /// Cancels all scheduled reminders
    func cancelAllReminders() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        print("🔕 All reminders cancelled")
    }
}

