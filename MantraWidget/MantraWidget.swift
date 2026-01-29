//
//  MantraWidget.swift
//  MantraWidget
//
//  Created by Linnea Sjoberg on 2026-01-28.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> MantraWidgetEntry {
        MantraWidgetEntry(date: Date(), streak: 5, totalMinutes: 125)
    }

    func getSnapshot(in context: Context, completion: @escaping (MantraWidgetEntry) -> Void) {
        let defaults = UserDefaults(suiteName: "group.marcodeb.VoiceMantra.MantraWidget")
        let streak = defaults?.integer(forKey: "mantraflow_current_streak") ?? 0
        let totalTime = defaults?.double(forKey: "mantraflow_total_time") ?? 0
        let totalMinutes = Int(totalTime / 60)
        
        completion(MantraWidgetEntry(date: Date(), streak: streak, totalMinutes: totalMinutes))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MantraWidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.marcodeb.VoiceMantra.MantraWidget")
        let streak = defaults?.integer(forKey: "mantraflow_current_streak") ?? 0
        let totalTime = defaults?.double(forKey: "mantraflow_total_time") ?? 0
        let totalMinutes = Int(totalTime / 60)
        
        let entry = MantraWidgetEntry(date: Date(), streak: streak, totalMinutes: totalMinutes)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Entry

struct MantraWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let totalMinutes: Int
}

// MARK: - Widget View

struct MantraWidgetEntryView: View {
    let entry: MantraWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Streak
            HStack(spacing: 12) {
                // Flame icon with glow (glow is only visible when streak > 0)
                ZStack {
                    if entry.streak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.brandAccent)
                            .blur(radius: 6)
                            .opacity(0.8)
                    }

                    Image(systemName: "flame.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.brandAccent)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(entry.streak) Days")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.brandText)

                    Text("Streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.brandTextSecondary)
                }
            }
            
            // Row 2: Total Minutes
            HStack(spacing: 12) {
                // Clock icon
                Image(systemName: "clock.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.brandAccent)

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(entry.totalMinutes) Mins")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.brandText)

                    Text("Total")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.brandTextSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, 8)
    }
}

// MARK: - Widget

struct MantraWidget: Widget {
    let kind: String = "MantraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MantraWidgetEntryView(entry: entry)
                .containerBackground(Color.brandBackground, for: .widget)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MantraWidget()
} timeline: {
    MantraWidgetEntry(date: .now, streak: 12, totalMinutes: 125)
    MantraWidgetEntry(date: .now, streak: 0, totalMinutes: 45)
}
