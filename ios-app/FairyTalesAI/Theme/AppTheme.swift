import SwiftUI

struct AppTheme {
    // Pastel Colors - Whimsical Design
    static let primaryPurple = Color(red: 0.75, green: 0.65, blue: 0.95) // Soft Purple
    static let accentPurple = Color(red: 0.85, green: 0.75, blue: 1.0) // Light Lavender
    static let pastelBlue = Color(red: 0.7, green: 0.85, blue: 1.0) // Soft Blue
    static let pastelPink = Color(red: 1.0, green: 0.8, blue: 0.9) // Soft Pink
    
    // Background Colors
    static let darkPurple = Color(red: 0.12, green: 0.12, blue: 0.2) // Dark background
    static let cardBackground = Color(red: 0.18, green: 0.18, blue: 0.28) // Card background
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.75)
    
    // Gradients
    static let purpleGradient = LinearGradient(
        colors: [primaryPurple, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Corner Radius for Whimsical Design
    static let cornerRadius: CGFloat = 25
}


