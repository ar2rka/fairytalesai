import SwiftUI

struct StoryCard: View {
    let story: Story
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple.opacity(0.5), AppTheme.accentPurple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 100)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.7))
                )
            
            Text(story.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .lineLimit(2)
                .frame(height: 40, alignment: .topLeading) // Fixed height for alignment
            
            Text("\(story.duration) \(LocalizationManager.shared.generateStoryMin) • \(LocalizationManager.shared.localizedThemeName(story.theme))")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.85)) // Lighter for better contrast
        }
        .frame(width: 150)
    }
}
