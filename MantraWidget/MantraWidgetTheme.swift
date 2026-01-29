//
//  MantraWidgetTheme.swift
//  MantraFlow
//
//  Created by Linnea Sjoberg on 2026-01-28.
//  Created for MantraWidget to share design system colors.
//

import SwiftUI

// MARK: - Brand Colors

extension Color {
  /// Deep dark background - Color(red: 15/255, green: 17/255, blue: 26/255)
  static let brandBackground = Color(red: 15/255, green: 17/255, blue: 26/255)
  
  /// Vibrant cyan accent - Color(red: 0/255, green: 247/255, blue: 222/255)
  static let brandAccent = Color(red: 0/255, green: 247/255, blue: 222/255)
  
  /// Soft white text - Color(red: 234/255, green: 234/255, blue: 234/255)
  static let brandText = Color(red: 234/255, green: 234/255, blue: 234/255)
  
  /// Dark field/card background - Color(red: 30/255, green: 35/255, blue: 50/255)
  static let brandField = Color(red: 30/255, green: 35/255, blue: 50/255)
  
  /// Secondary text - slightly dimmed brandText
  static let brandTextSecondary = Color(red: 234/255, green: 234/255, blue: 234/255).opacity(0.6)
}
