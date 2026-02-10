import SwiftUI

enum ThemeMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct AppTheme {
    // Pastel Colors - Whimsical Design (same for both themes)
    static let primaryPurple = Color(red: 0.75, green: 0.65, blue: 0.95) // Soft Purple
    static let accentPurple = Color(red: 0.85, green: 0.75, blue: 1.0) // Light Lavender
    static let pastelBlue = Color(red: 0.7, green: 0.85, blue: 1.0) // Soft Blue
    static let pastelPink = Color(red: 1.0, green: 0.8, blue: 0.9) // Soft Pink
    
    // Dark Theme Colors - Bedtime-friendly deep purples and midnight blues
    static let darkPurple = Color(red: 0.12, green: 0.08, blue: 0.22) // Dark purple background (visible purple, not black)
    static let darkCardBackground = Color(red: 0.15, green: 0.15, blue: 0.25) // Card background
    static let darkTextPrimary = Color.white
    static let darkTextSecondary = Color(white: 0.85) // Lighter for better contrast at low brightness
    
    // Light Theme Colors
    static let lightPurple = Color(red: 0.98, green: 0.97, blue: 1.0) // Light background
    static let lightCardBackground = Color.white // Card background
    static let lightTextPrimary = Color(red: 0.12, green: 0.12, blue: 0.2)
    static let lightTextSecondary = Color(red: 0.4, green: 0.4, blue: 0.5)
    
    // Dynamic Colors (based on color scheme)
    static func backgroundColor(for colorScheme: ColorScheme?) -> Color {
        switch colorScheme {
        case .light:
            return lightPurple
        case .dark, .none:
            return darkPurple
        @unknown default:
            return darkPurple
        }
    }
    
    static func cardBackground(for colorScheme: ColorScheme?) -> Color {
        switch colorScheme {
        case .light:
            return lightCardBackground
        case .dark, .none:
            return darkCardBackground
        @unknown default:
            return darkCardBackground
        }
    }
    
    static func textPrimary(for colorScheme: ColorScheme?) -> Color {
        switch colorScheme {
        case .light:
            return lightTextPrimary
        case .dark, .none:
            return darkTextPrimary
        @unknown default:
            return darkTextPrimary
        }
    }
    
    static func textSecondary(for colorScheme: ColorScheme?) -> Color {
        switch colorScheme {
        case .light:
            return lightTextSecondary
        case .dark, .none:
            return darkTextSecondary
        @unknown default:
            return darkTextSecondary
        }
    }
    
    // Gradients
    static let purpleGradient = LinearGradient(
        colors: [primaryPurple, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Corner Radius for Whimsical Design
    static let cornerRadius: CGFloat = 25
    
    // Legacy static properties for backward compatibility
    static let textPrimary = darkTextPrimary
    static let textSecondary = darkTextSecondary
    static let cardBackground = darkCardBackground
}


