import SwiftUI

/// Horizontal scroll of recent stories on HomeView with "View all" link.
/// Tapping a story opens it via Library (StoryContentView) for consistent UX.
struct RecentMagicSection: View {
    let stories: [Story]
    var sectionTitleSize: CGFloat = 20
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator

    var body: some View {
        if !stories.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(LocalizationManager.shared.homeRecentMagic)
                        .font(.system(size: sectionTitleSize, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))

                    Spacer()

                    NavigationLink(LocalizationManager.shared.homeViewAll, destination: LibraryView())
                        .foregroundColor(AppTheme.primaryPurple)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(stories.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5)) { story in
                            Button {
                                navigationCoordinator.switchToLibraryAndOpenStory(story.id)
                            } label: {
                                StoryCard(story: story)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
