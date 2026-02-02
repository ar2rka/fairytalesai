import SwiftUI

struct FreeDemoStoryCard: View {
    let story: Story
    @Environment(\.colorScheme) var colorScheme
    
    private var themeEmoji: String {
        switch story.theme.lowercased() {
        case "space": return "🚀"
        case "pirates": return "🏴‍☠️"
        case "animals": return "🦁"
        case "fairies": return "🧚"
        case "forest", "adventure": return "🌲"
        case "dragon": return "🐉"
        default: return "📖"
        }
    }
    
    private var themeGradient: [Color] {
        switch story.theme.lowercased() {
        case "space":
            return [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.1, blue: 0.3)]
        case "pirates":
            return [Color(red: 0.3, green: 0.2, blue: 0.1), Color(red: 0.4, green: 0.3, blue: 0.15)]
        case "animals":
            return [Color(red: 0.2, green: 0.4, blue: 0.2), Color(red: 0.15, green: 0.35, blue: 0.15)]
        case "fairies":
            return [Color(red: 0.4, green: 0.2, blue: 0.4), Color(red: 0.5, green: 0.3, blue: 0.5)]
        case "forest", "adventure":
            return [Color(red: 0.1, green: 0.3, blue: 0.2), Color(red: 0.15, green: 0.4, blue: 0.25)]
        case "dragon":
            return [Color(red: 0.4, green: 0.1, blue: 0.1), Color(red: 0.5, green: 0.15, blue: 0.15)]
        default:
            return [AppTheme.primaryPurple.opacity(0.6), AppTheme.accentPurple.opacity(0.6)]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: themeGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 120)
                
                Text(themeEmoji)
                    .font(.system(size: 60))
                
                // Age category badge in top-left corner
                VStack {
                    HStack {
                        Text(story.ageCategory)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.4))
                            )
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(2)
                    .frame(height: 45, alignment: .topLeading)
                
                Text("\(story.duration) min • \(story.theme)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.85)) // Lighter for better contrast
            }
        }
        .frame(width: 200)
    }
}
