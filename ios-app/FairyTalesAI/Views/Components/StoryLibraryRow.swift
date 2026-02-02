import SwiftUI

struct StoryLibraryRow: View {
    let story: Story
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            NavigationLink(destination: StoryContentView(story: story)) {
                HStack(spacing: 16) {
                    // Thumbnail
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primaryPurple.opacity(0.5), AppTheme.accentPurple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.7))
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(story.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
                        HStack(spacing: 8) {
                            if let childId = story.childId {
                                Text(childName(for: childId))
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                            if let language = story.language, let flag = FlagEmoji.flag(for: language) {
                                Text(flag)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.cardBackground(for: colorScheme).opacity(0.5))
                                    .cornerRadius(6)
                            }
                            if let rating = story.rating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                    Text("\(rating)/10")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(AppTheme.primaryPurple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.primaryPurple.opacity(0.2))
                                .cornerRadius(6)
                            }
                            Text("\(story.duration) min")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    private func childName(for childId: UUID) -> String {
        childrenStore.children.first(where: { $0.id == childId })?.name ?? LocalizationManager.shared.libraryUnknown
    }
}
