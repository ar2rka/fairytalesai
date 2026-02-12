import SwiftUI

struct ThemeSelectionButton: View {
    let theme: StoryTheme
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var tapScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact()
            withAnimation(.easeOut(duration: 0.2)) {
                tapScale = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.2)) {
                    tapScale = 1.0
                }
            }
            action()
        }) {
            VStack(spacing: 12) {
                Text(theme.emoji)
                    .font(.system(size: 40))
                
                VStack(spacing: 4) {
                    Text(theme.localizedName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary(for: colorScheme))
                    
                    Text(theme.localizedDescription)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(white: 0.85))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isSelected ? AppTheme.primaryPurple : Color.clear,
                        lineWidth: isSelected ? 3 : 0
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.primaryPurple.opacity(0.5) : .clear,
                radius: isSelected ? 6 : 0,
                x: 0,
                y: 0
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .padding(8)
                }
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .scaleEffect(tapScale)
            .animation(.easeOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
