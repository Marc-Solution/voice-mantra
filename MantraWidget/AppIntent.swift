//
//  AppIntent.swift
//  MantraWidget
//
//  Created by Linnea Sjoberg on 2026-01-26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Mantra Widget Configuration" }
}
