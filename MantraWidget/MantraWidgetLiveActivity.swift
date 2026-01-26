//
//  MantraWidgetLiveActivity.swift
//  MantraWidget
//
//  Created by Linnea Sjoberg on 2026-01-26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MantraWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MantraWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MantraWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MantraWidgetAttributes {
    fileprivate static var preview: MantraWidgetAttributes {
        MantraWidgetAttributes(name: "World")
    }
}

extension MantraWidgetAttributes.ContentState {
    fileprivate static var smiley: MantraWidgetAttributes.ContentState {
        MantraWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MantraWidgetAttributes.ContentState {
         MantraWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MantraWidgetAttributes.preview) {
   MantraWidgetLiveActivity()
} contentStates: {
    MantraWidgetAttributes.ContentState.smiley
    MantraWidgetAttributes.ContentState.starEyes
}
