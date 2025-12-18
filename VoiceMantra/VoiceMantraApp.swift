//  AppformationsApp.swift
//  Appformations
//
//  Created by Marco Deb on 2025-12-11.
//

import SwiftUI

@main
struct AppFirmationsApp: App {
  @StateObject private var store = AppStore()

  var body: some Scene {
    WindowGroup {
      HomeView()
        .environmentObject(store)
    }
  }
}
