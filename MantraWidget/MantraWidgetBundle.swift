//
//  MantraWidgetBundle.swift
//  MantraWidget
//
//  Created by Linnea Sjoberg on 2026-01-28.
//

import WidgetKit
import SwiftUI

@main
struct MantraWidgetBundle: WidgetBundle {
    var body: some Widget {
        MantraWidget()
        MantraWidgetControl()
        MantraWidgetLiveActivity()
    }
}
