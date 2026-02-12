import SwiftUI

/// Horizontal scroll of daily free stories on HomeView.
struct DailyFreeStorySection: View {
    let stories: [Story]
    let isLoading: Bool
    var sectionTitleSize: CGFloat = 20
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if !stories.isEmpty || isLoading {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizationManager.shared.homeDailyFreeStory)
                    .font(.system(size: sectionTitleSize, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .padding(.horizontal)
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(stories) { story in
                                NavigationLink(destination: StoryReadingView(story: story)) {
                                    FreeDemoStoryCard(story: story)
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
}
