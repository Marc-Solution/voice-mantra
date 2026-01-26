//
//  MantraWidget.swift
//  MantraWidget
//
//  Created by Linnea Sjoberg on 2026-01-26.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), streak: 5)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration, streak: 5)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Read streak from App Group
        let defaults = UserDefaults(suiteName: "group.com.mantra.voice")
        let streak = defaults?.integer(forKey: "mantraflow_current_streak") ?? 0
        
        let entry = SimpleEntry(date: Date(), configuration: configuration, streak: streak)
        return Timeline(entries: [entry], policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let streak: Int
}

struct MantraWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 12) {
            // Flame icon with glow
            ZStack {
                // Glow effect (only if streak > 0)
                if entry.streak > 0 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.brandAccent)
                        .blur(radius: 6)
                        .opacity(0.8)
                }
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(entry.streak > 0 ? .brandAccent : .gray.opacity(0.5))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MantraWidget: Widget {
    let kind: String = "MantraWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            MantraWidgetEntryView(entry: entry)
                .containerBackground(Color.brandBackground, for: .widget)
        }
    }
}

#Preview(as: .systemSmall) {
    MantraWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), streak: 5)
}
