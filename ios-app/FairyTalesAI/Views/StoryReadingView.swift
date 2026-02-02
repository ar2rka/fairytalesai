import SwiftUI

struct StoryReadingView: View {
    let story: Story
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showingPaywall = false
    @State private var showShareSheet = false
    
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
                    
                    // Story Content
                    Text(story.content)
                        .font(.system(size: 18))
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
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    }
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationView {
                PaywallView()
                    .environmentObject(userSettings)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [
                "\(story.title)\n\n\(story.content)"
            ])
        }
    }
}
