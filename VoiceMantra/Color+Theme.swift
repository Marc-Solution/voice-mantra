//
//  Color+Theme.swift
//  MantraFlow
//
//  Brand theme colors and styling helpers
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

// MARK: - Brand Button Style

struct BrandPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color.brandAccent : Color.brandAccent.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BrandPrimaryButtonStyle {
    static var brandPrimary: BrandPrimaryButtonStyle { BrandPrimaryButtonStyle() }
}

// MARK: - Brand TextField Style

struct BrandTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandField)
            )
            .foregroundColor(.brandText)
    }
}

extension View {
    func brandTextFieldStyle() -> some View {
        self.modifier(BrandTextFieldStyle())
    }
}

// MARK: - Brand Card Style

struct BrandCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.brandField)
            )
    }
}

extension View {
    func brandCardStyle() -> some View {
        self.modifier(BrandCardStyle())
    }
}

// MARK: - Brand Background Modifier

struct BrandBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.brandBackground.ignoresSafeArea())
    }
}

extension View {
    func brandBackground() -> some View {
        self.modifier(BrandBackgroundModifier())
    }
}

