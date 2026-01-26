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
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct MantraWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        HStack(spacing: 12) {
            // Flame icon with glow
            ZStack {
                // Glow effect
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.brandAccent)
                    .blur(radius: 6)
                    .opacity(0.8)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.brandAccent)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text("12 Days")
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
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent())
}
