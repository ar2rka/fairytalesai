import SwiftUI

struct ProtagonistStyleSelector: View {
    @Binding var selectedStyle: StoryStyle
    @Environment(\.colorScheme) var colorScheme
    
    private let styles: [StoryStyle] = [.hero, .boy, .girl]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ForEach(styles, id: \.self) { style in
                    StyleCard(
                        style: style,
                        isSelected: selectedStyle == style
                    ) {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedStyle = style
                        }
                    }
                }
            }
            
            // Caption
            Text(LocalizationManager.shared.styleSelectorCaption)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                .padding(.top, 2)
        }
    }
}

struct StyleCard: View {
    let style: StoryStyle
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(style.icon)
                    .font(.system(size: 26))
                
                Text(style.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [AppTheme.primaryPurple.opacity(0.2), AppTheme.accentPurple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        AppTheme.cardBackground(for: colorScheme)
                    }
                }
            )
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isSelected ? AppTheme.primaryPurple : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.primaryPurple.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProtagonistStyleSelector(selectedStyle: .constant(.hero))
        .padding()
        .preferredColorScheme(.dark)
}
