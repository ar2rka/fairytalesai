import SwiftUI

struct StoryContentView: View {
    let story: Story
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var createStoryPresentation: CreateStoryPresentation
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var canContinueStory: Bool {
        story.childId != nil
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(story.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    
                    // Story metadata
                    HStack(spacing: 16) {
                        if let language = story.language, let flag = FlagEmoji.flag(for: language) {
                            Text(flag)
                                .font(.system(size: 20))
                        }
                        
                        if let rating = story.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text("\(rating)/10")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppTheme.primaryPurple)
                        }
                        
                        Text("\(story.duration) \(LocalizationManager.shared.libraryMinRead)")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                    
                    Divider()
                        .background(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
                    
                    // Listen Button with Premium Lock (inactive when not premium)
                    Button(action: {
                        // Start audio playback — only reachable when premium
                    }) {
                        HStack {
                            Image(systemName: userSettings.isPremium ? "play.circle.fill" : "lock.fill")
                            Text(userSettings.isPremium ? LocalizationManager.shared.storyReadingListen : LocalizationManager.shared.storyReadingListenPremium)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userSettings.isPremium ? AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.5))
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    .disabled(!userSettings.isPremium)
                    .allowsHitTesting(userSettings.isPremium)
                    
                    // Story content
                    Text(story.content)
                        .font(.system(size: userSettings.storyFontSize))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        .lineSpacing(8)
                }
                .padding()
            }
        }
        .navigationTitle(LocalizationManager.shared.storyReadingStory)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    guard let childId = story.childId else { return }
                    let params = StoryGeneratingParams(
                        childId: childId,
                        duration: story.duration,
                        theme: story.theme,
                        plot: nil,
                        parentId: story.id,
                        children: childrenStore.children,
                        language: userSettings.languageCode
                    )
                    createStoryPresentation.presentGenerating(params: params)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.pages")
                        Text("Continue")
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(canContinueStory ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                }
                .disabled(!canContinueStory)
                .accessibilityLabel(LocalizationManager.shared.homeContinueLastNight)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Decrease font size button
                    Button(action: {
                        if userSettings.storyFontSize > 12 {
                            userSettings.storyFontSize -= 2
                        }
                    }) {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundColor(userSettings.storyFontSize > 12 ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    }
                    .disabled(userSettings.storyFontSize <= 12)
                    
                    // Increase font size button
                    Button(action: {
                        if userSettings.storyFontSize < 24 {
                            userSettings.storyFontSize += 2
                        }
                    }) {
                        Image(systemName: "textformat.size.larger")
                            .foregroundColor(userSettings.storyFontSize < 24 ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    }
                    .disabled(userSettings.storyFontSize >= 24)
                }
            }
        }
    }
}
