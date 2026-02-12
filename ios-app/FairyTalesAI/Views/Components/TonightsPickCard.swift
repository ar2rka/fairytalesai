import SwiftUI

/// Highlighted "Tonight's Pick" theme card with badge and subtle glow. Same tap behavior as ThemeButton.
struct TonightsPickCard: View {
    let theme: StoryTheme
    var onTap: ((StoryTheme) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact()
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
            .background(theme.color.opacity(0.18))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(theme.color.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: theme.color.opacity(0.35), radius: 10, x: 0, y: 2)
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(bounceScale)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
