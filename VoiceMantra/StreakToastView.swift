//
//  StreakToastView.swift
//  MantraFlow
//
//  Celebration toast overlay for streak achievements
//

import SwiftUI

/// A brief, elegant toast notification for streak celebrations
struct StreakToastView: View {
    let streakCount: Int
    let isNewStreak: Bool  // True if this is Day 1
    
    @State private var isVisible: Bool = false
    @State private var offset: CGFloat = -100
    
    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 12) {
                    // Flame icon with glow
                    ZStack {
                        // Glow effect
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.brandAccent)
                            .blur(radius: 8)
                            .opacity(0.6)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.brandAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isNewStreak ? "Streak Started!" : "Streak Maintained!")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.brandText)
                        
                        Text("Day \(streakCount)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.brandAccent)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.brandField)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.brandAccent.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.brandAccent.opacity(0.2), radius: 12, x: 0, y: 4)
                )
                .offset(y: offset)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding(.top, 60)  // Safe area clearance
        .onAppear {
            showToast()
        }
    }
    
    private func showToast() {
        // Animate in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isVisible = true
            offset = 0
        }
        
        // Auto-dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                offset = -100
                isVisible = false
            }
        }
    }
}

/// View modifier to easily add streak toast to any view
struct StreakToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let streakCount: Int
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                StreakToastView(
                    streakCount: streakCount,
                    isNewStreak: streakCount == 1
                )
                .onDisappear {
                    // Reset after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

extension View {
    /// Displays a streak celebration toast
    func streakToast(isShowing: Binding<Bool>, streakCount: Int) -> some View {
        modifier(StreakToastModifier(isShowing: isShowing, streakCount: streakCount))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.brandBackground.ignoresSafeArea()
        
        VStack {
            Text("Main Content")
                .foregroundColor(.brandText)
        }
        
        StreakToastView(streakCount: 7, isNewStreak: false)
    }
}

