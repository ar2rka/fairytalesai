import SwiftUI

struct ThemeButton: View {
    let theme: StoryTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var isSelected = false
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact()
            
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
            .background(theme.color.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isSelected ? theme.color : theme.color.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .shadow(
                        color: isSelected ? theme.color.opacity(0.6) : .clear,
                        radius: isSelected ? 8 : 0
                    )
            )
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(bounceScale)
        }
    }
}
