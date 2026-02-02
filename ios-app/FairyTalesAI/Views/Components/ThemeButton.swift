import SwiftUI

struct ThemeButton: View {
    let theme: StoryTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var isSelected = false
    @State private var bounceScale: CGFloat = 1.0
    
    private var themeColor: Color {
        switch theme.name.lowercased() {
        case "space":
            return Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
        case "pirates":
            return Color(red: 0.8, green: 0.6, blue: 0.2) // Gold
        case "dinosaurs":
            return Color(red: 0.2, green: 0.8, blue: 0.2) // Green
        case "mermaids":
            return Color(red: 0.2, green: 0.6, blue: 1.0) // Blue
        case "animals":
            return Color(red: 0.4, green: 0.7, blue: 0.3) // Green
        case "mystery":
            return Color(red: 0.6, green: 0.3, blue: 0.8) // Purple
        case "magic school":
            return Color(red: 0.8, green: 0.3, blue: 0.8) // Magenta
        case "robots":
            return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        default:
            return AppTheme.primaryPurple
        }
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Toggle selection
            isSelected.toggle()
            
            // Bounce animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounceScale = 1.2
            }
            
            // Reset bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceScale = 1.0
                }
            }
        }) {
            VStack(spacing: 6) {
                Text(theme.emoji)
                    .font(.system(size: 28))
                
                Text(theme.localizedName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(themeColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isSelected ? themeColor : themeColor.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .shadow(
                        color: isSelected ? themeColor.opacity(0.6) : .clear,
                        radius: isSelected ? 8 : 0
                    )
            )
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(bounceScale)
        }
    }
}
