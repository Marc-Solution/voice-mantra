//
//  StreakManager.swift
//  MantraFlow
//
//  Manages streak tracking, total time, and celebration logic
//

import Foundation
import SwiftUI
import Combine
import WidgetKit

/// Manages persistent streak data and total listening time
final class StreakManager: ObservableObject {
  
  // MARK: - Singleton
  static let shared = StreakManager()
  
  // MARK: - UserDefaults Keys
  private enum Keys {
    static let totalTime = "mantraflow_total_time"
    static let lastSessionDate = "mantraflow_last_session_date"
    static let currentStreak = "mantraflow_current_streak"
    static let todayTime = "mantraflow_today_time"
  }
  
  // MARK: - Published Properties
  @Published private(set) var totalTime: TimeInterval = 0
  @Published private(set) var currentStreak: Int = 0
  @Published private(set) var lastSessionDate: Date?
  @Published private(set) var todayTime: TimeInterval = 0
  
  /// Indicates if the streak was just increased (for celebration trigger)
  @Published var streakJustIncreased: Bool = false
  
  // MARK: - Private Properties
  private let defaults = UserDefaults.standard
  private let sharedDefaults = UserDefaults(suiteName: "group.marcodeb.MantraFlow.MantraWidget")
  private let calendar = Calendar.current
  
  // MARK: - Initialization
  private init() {
    loadPersistedData()
    checkAndResetStreak()
  }
  
  // MARK: - Persistence
  
  private func loadPersistedData() {
    totalTime = defaults.double(forKey: Keys.totalTime)
    currentStreak = defaults.integer(forKey: Keys.currentStreak)
    lastSessionDate = defaults.object(forKey: Keys.lastSessionDate) as? Date
    todayTime = defaults.double(forKey: Keys.todayTime)
    
    print("📊 StreakManager loaded: Streak=\(currentStreak), TotalTime=\(formattedTotalTime), LastSession=\(lastSessionDate?.description ?? "Never")")
  }
  
  private func save() {
    defaults.set(totalTime, forKey: Keys.totalTime)
    defaults.set(currentStreak, forKey: Keys.currentStreak)
    defaults.set(lastSessionDate, forKey: Keys.lastSessionDate)
    defaults.set(todayTime, forKey: Keys.todayTime)
    defaults.synchronize()
    
    // Sync to shared container for widget
    sharedDefaults?.set(currentStreak, forKey: Keys.currentStreak)
    sharedDefaults?.set(totalTime, forKey: Keys.totalTime)
    sharedDefaults?.set(todayTime, forKey: Keys.todayTime)
    
    // Reload widget
    WidgetCenter.shared.reloadAllTimelines()
  }
  
  // MARK: - Streak Logic
  
  /// Checks if the streak should be reset based on last completion date
  /// Resets to 0 if a full calendar day has been missed (lastCompletionDate is older than yesterday)
  /// This should be called on app launch and when the view appears to handle midnight crossing
  func checkAndResetStreak() {
    guard let lastDate = lastSessionDate else {
      // No previous session - streak remains 0
      return
    }
    
    let daysDifference = daysBetween(lastDate, and: Date())
    
    // Always reset todayTime if the last session was NOT today
    if daysDifference > 0 {
      print("🗓️ New day detected (\(daysDifference) day(s) since last session). Resetting todayTime to 0.")
      todayTime = 0
      save()
    }
    
    if daysDifference >= 2 {
      // Streak broken - a full calendar day was missed, reset to 0
      print("💔 Streak broken! \(daysDifference) days since last session. Resetting streak to 0.")
      currentStreak = 0
      save()
    } else {
      print("✅ Streak still active (\(daysDifference) day(s) since last session)")
    }
  }
  
  /// Records a completed mantra session
  /// - Parameter duration: Duration of the session in seconds
  /// - Returns: True if streak increased, false otherwise
  @discardableResult
  func recordCompletion(duration: TimeInterval) -> Bool {
    let now = Date()
    var streakIncreased = false
    
    // Always add to total time
    totalTime += duration
    todayTime += duration
    print("⏱️ Added \(Int(duration))s to total and today's time. New total: \(formattedTotalTime)")
    
    // Determine streak action based on last session date
    if let lastDate = lastSessionDate {
      let daysDifference = daysBetween(lastDate, and: now)
      
      if daysDifference == 0 {
        // Same day - don't increment, already counted
        print("📅 Same day session - streak unchanged at \(currentStreak)")
      } else if daysDifference == 1 {
        // Yesterday - increment streak!
        currentStreak += 1
        streakIncreased = true
        print("🔥 Streak incremented! Now at \(currentStreak) days")
      } else {
        // 2+ days gap - start fresh at 1
        currentStreak = 1
        streakIncreased = true
        print("🆕 New streak started after \(daysDifference) day gap")
      }
    } else {
      // First ever session
      currentStreak = 1
      streakIncreased = true
      print("🎉 First session ever! Streak started at 1")
    }
    
    // Update last session date
    lastSessionDate = now
    
    // Persist changes
    save()
    
    // Update celebration flag
    if streakIncreased {
      streakJustIncreased = true
    }
    
    return streakIncreased
  }
  
  /// Calculates calendar days between two dates (ignoring time)
  private func daysBetween(_ from: Date, and to: Date) -> Int {
    let fromStart = calendar.startOfDay(for: from)
    let toStart = calendar.startOfDay(for: to)
    
    let components = calendar.dateComponents([.day], from: fromStart, to: toStart)
    return components.day ?? 0
  }
  
  // MARK: - Formatted Output
  
  /// Returns formatted total time string
  /// Under 60 mins: "X mins" | Over 60 mins: "Xh Ym"
  var formattedTotalTime: String {
    let totalMinutes = Int(totalTime / 60)
    
    if totalMinutes < 1 {
      return "0 mins"
    } else if totalMinutes < 60 {
      return "\(totalMinutes) min\(totalMinutes == 1 ? "" : "s")"
    } else {
      let hours = totalMinutes / 60
      let mins = totalMinutes % 60
      if mins == 0 {
        return "\(hours)h"
      } else {
        return "\(hours)h \(mins)m"
      }
    }
  }
  
  /// Returns true if the streak is currently active (played today or yesterday)
  var isStreakActive: Bool {
    guard let lastDate = lastSessionDate else { return false }
    let daysDifference = daysBetween(lastDate, and: Date())
    return daysDifference <= 1
  }
  
  /// Clears the celebration flag (call after showing toast)
  func clearCelebrationFlag() {
    streakJustIncreased = false
  }
  
  // MARK: - Debug/Testing
  
  #if DEBUG
  func resetAllData() {
    totalTime = 0
    currentStreak = 0
    lastSessionDate = nil
    save()
    print("🗑️ StreakManager data reset")
  }
  #endif
}

