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
        MantraWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (MantraWidgetEntry) -> Void) {
        completion(MantraWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MantraWidgetEntry>) -> Void) {
        let entry = MantraWidgetEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Entry

struct MantraWidgetEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget View

struct MantraWidgetEntryView: View {
    let entry: MantraWidgetEntry

    var body: some View {
        HStack(spacing: 12) {
            // Flame icon with glow
            ZStack {
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
    MantraWidgetEntry(date: .now)
}
