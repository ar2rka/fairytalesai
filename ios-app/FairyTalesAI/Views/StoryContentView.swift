import SwiftUI

struct StoryContentView: View {
    let story: Story
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showingPaywall = false
    
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
                    
                    // Listen Button with Premium Lock
                    Button(action: {
                        if !userSettings.isPremium {
                            showingPaywall = true
                        } else {
                            // Start audio playback
                            // In production, this would start the audio narration
                        }
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
        .sheet(isPresented: $showingPaywall) {
            NavigationView {
                PaywallView()
                    .environmentObject(userSettings)
            }
        }
    }
}
