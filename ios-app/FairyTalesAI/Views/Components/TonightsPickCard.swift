import SwiftUI

/// Highlighted "Tonight's Pick" theme card with badge and subtle glow. Same tap behavior as ThemeButton.
struct TonightsPickCard: View {
    let theme: StoryTheme
    var onTap: ((StoryTheme) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var bounceScale: CGFloat = 1.0
    
    private var themeColor: Color {
        switch theme.name.lowercased() {
        case "space": return Color(red: 1.0, green: 0.65, blue: 0.0)
        case "pirates": return Color(red: 0.8, green: 0.6, blue: 0.2)
        case "dinosaurs": return Color(red: 0.2, green: 0.8, blue: 0.2)
        case "mermaids": return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "animals": return Color(red: 0.4, green: 0.7, blue: 0.3)
        case "mystery": return Color(red: 0.6, green: 0.3, blue: 0.8)
        case "magic school": return Color(red: 0.8, green: 0.3, blue: 0.8)
        case "robots": return Color(red: 0.5, green: 0.5, blue: 0.5)
        default: return AppTheme.primaryPurple
        }
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap?(theme)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounceScale = 1.05
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceScale = 1.0
                }
            }
        }) {
            VStack(spacing: 8) {
                Text(theme.emoji)
                    .font(.system(size: 32))
                
                Text(theme.localizedName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(themeColor.opacity(0.18))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(themeColor.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: themeColor.opacity(0.35), radius: 10, x: 0, y: 2)
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(bounceScale)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
