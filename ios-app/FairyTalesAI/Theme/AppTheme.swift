import SwiftUI

struct AppTheme {
    // Colors
    static let primaryPurple = Color(red: 0.55, green: 0.49, blue: 0.78) // #8B7EC8
    static let darkPurple = Color(red: 0.1, green: 0.1, blue: 0.18) // #1A1A2E
    static let lightPurple = Color(red: 0.2, green: 0.2, blue: 0.3)
    static let accentPurple = Color(red: 0.7, green: 0.6, blue: 0.95)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.25)
    
    // Gradients
    static let purpleGradient = LinearGradient(
        colors: [primaryPurple, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

