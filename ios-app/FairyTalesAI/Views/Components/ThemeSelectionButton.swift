import SwiftUI

struct ThemeSelectionButton: View {
    let theme: StoryTheme
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var bounceScale: CGFloat = 1.0
    
    private var themeColor: Color {
        switch theme.name.lowercased() {
        case "space": return Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
        case "pirates": return Color(red: 0.8, green: 0.6, blue: 0.2) // Gold
        case "dinosaurs": return Color(red: 0.2, green: 0.8, blue: 0.2) // Green
        case "mermaids": return Color(red: 0.2, green: 0.6, blue: 1.0) // Blue
        case "animals": return Color(red: 0.4, green: 0.7, blue: 0.3) // Green
        case "mystery": return Color(red: 0.6, green: 0.3, blue: 0.8) // Purple
        case "magic school": return Color(red: 0.8, green: 0.3, blue: 0.8) // Magenta
        case "robots": return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        default: return AppTheme.primaryPurple
        }
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Bounce animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounceScale = 1.1
            }
            
            // Reset bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceScale = 1.0
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
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(white: 0.85)) // Lighter for better contrast
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isSelected ? themeColor : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
                    .shadow(
                        color: isSelected ? themeColor.opacity(0.6) : .clear,
                        radius: isSelected ? 8 : 0
                    )
            )
            .overlay(
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
            .scaleEffect(bounceScale)
        }
    }
}
