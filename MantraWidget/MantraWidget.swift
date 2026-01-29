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
        MantraWidgetEntry(date: Date(), streak: 5, totalMinutes: 125, todayMinutes: 15)
    }

    func getSnapshot(in context: Context, completion: @escaping (MantraWidgetEntry) -> Void) {
        let defaults = UserDefaults(suiteName: "group.marcodeb.VoiceMantra.MantraWidget")
        let streak = defaults?.integer(forKey: "mantraflow_current_streak") ?? 0
        let totalTime = defaults?.double(forKey: "mantraflow_total_time") ?? 0
        let totalMinutes = Int(totalTime / 60)
        let todayTime = defaults?.double(forKey: "mantraflow_today_time") ?? 0
        let todayMinutes = Int(todayTime / 60)
        
        completion(MantraWidgetEntry(date: Date(), streak: streak, totalMinutes: totalMinutes, todayMinutes: todayMinutes))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MantraWidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.marcodeb.VoiceMantra.MantraWidget")
        let streak = defaults?.integer(forKey: "mantraflow_current_streak") ?? 0
        let totalTime = defaults?.double(forKey: "mantraflow_total_time") ?? 0
        let totalMinutes = Int(totalTime / 60)
        let todayTime = defaults?.double(forKey: "mantraflow_today_time") ?? 0
        let todayMinutes = Int(todayTime / 60)
        
        let entry = MantraWidgetEntry(date: Date(), streak: streak, totalMinutes: totalMinutes, todayMinutes: todayMinutes)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Entry

struct MantraWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let totalMinutes: Int
    let todayMinutes: Int
}

// MARK: - Widget View

struct MantraWidgetEntryView: View {
    let entry: MantraWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            //  Streak
            HStack(spacing: 8) {
                ZStack {
                    if entry.streak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.brandAccent)
                            .blur(radius: 6)
                            .opacity(0.5)
                    }
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.brandAccent)
                }

                HStack(spacing: 4) {
                    Text("\(entry.streak) ")
                        .font(.system(size:24, weight: .bold, design: .rounded))
                        .foregroundColor(.brandText)
                    Text("Days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.brandTextSecondary)
                }
            }
            
            
            //  Motivational Message
            Text(entry.todayMinutes > 0 ? "Meditated today:" : "Time for your daily session?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.brandAccent)
            
            // Today's Minutes if done today
            if entry.todayMinutes > 0 {
                VStack(spacing: 2) {
                    HStack{
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.brandAccent)
                        
                        HStack(spacing: 4) {
                            Text("\(entry.todayMinutes) ")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.brandText)

                            Text("Mins ")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.brandTextSecondary)
                        }
                        
                    }
                  
                }
            }
            


            // Row 4: Total Minutes
         //   HStack(spacing: 12) {
         //       Image(systemName: "clock.fill")
           //         .font(.system(size: 22, weight: .bold))
             //       .foregroundColor(.brandAccent)
//
  //              VStack(alignment: .leading, spacing: 1) {
    //                Text("\(entry.totalMinutes)")
      //                  .font(.system(size: 15, weight: .bold, design: //.rounded))
            //            .foregroundColor(.brandText)
//
  //                  Text("Mins Total")
    //                    .font(.system(size: 11, weight: .medium))
      //                  .foregroundColor(.brandTextSecondary)
        //        }
          //  }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, 4)
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
    MantraWidgetEntry(date: .now, streak: 12, totalMinutes: 125, todayMinutes: 20)
    MantraWidgetEntry(date: .now, streak: 0, totalMinutes: 45, todayMinutes: 0)
}
