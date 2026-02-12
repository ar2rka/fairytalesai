import SwiftUI

struct StoryReadingView: View {
    let story: Story
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var createStoryPresentation: CreateStoryPresentation
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showShareSheet = false

    private var canContinueStory: Bool {
        story.childId != nil
    }

    private func continuationSummary(from story: Story) -> String {
        if let plot = story.plot, !plot.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Continue the adventure. Previous story: \"\(story.title)\". Summary: \(plot). Write a new chapter that continues this story."
        }
        let snippet = String(story.content.prefix(500)).trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = story.content.count > 500 ? "…" : ""
        return "Continue the adventure. Previous story: \"\(story.title)\". Here is how it went: \(snippet)\(suffix) Write a new chapter that continues this story."
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Story Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(story.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                Text("\(story.duration) min")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            Text("•")
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            Text(story.theme)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.primaryPurple)
                        }
                    }
                    
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
                    
                    // Story Content
                    Text(story.content)
                        .font(.system(size: userSettings.storyFontSize))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        .lineSpacing(12)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
        }
        .navigationTitle(LocalizationManager.shared.storyReadingStory)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {
                        if userSettings.storyFontSize > 12 {
                            userSettings.storyFontSize -= 2
                        }
                    }) {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundColor(userSettings.storyFontSize > 12 ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    }
                    .disabled(userSettings.storyFontSize <= 12)

                    Button(action: {
                        if userSettings.storyFontSize < 24 {
                            userSettings.storyFontSize += 2
                        }
                    }) {
                        Image(systemName: "textformat.size.larger")
                            .foregroundColor(userSettings.storyFontSize < 24 ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    }
                    .disabled(userSettings.storyFontSize >= 24)

                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    }

                    Button(action: {
                        guard let childId = story.childId else { return }
                        let params = StoryGeneratingParams(
                            childId: childId,
                            duration: story.duration,
                            theme: story.theme,
                            plot: continuationSummary(from: story),
                            parentId: story.id,
                            children: childrenStore.children,
                            language: userSettings.languageCode
                        )
                        createStoryPresentation.presentGenerating(params: params)
                    }) {
                        Image(systemName: "book.pages")
                            .foregroundColor(canContinueStory ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    }
                    .disabled(!canContinueStory)
                    .accessibilityLabel(LocalizationManager.shared.homeContinueLastNight)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [
                "\(story.title)\n\n\(story.content)"
            ])
        }
    }
}
