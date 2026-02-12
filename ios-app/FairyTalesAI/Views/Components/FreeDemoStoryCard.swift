import SwiftUI

struct FreeDemoStoryCard: View {
    let story: Story
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: StoryTheme.gradient(for: story.theme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 120)
                
                Text(StoryTheme.emoji(for: story.theme))
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
