import SwiftUI

struct StoryResultView: View {
    let story: Story
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(story.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
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
                                Text(userSettings.isPremium ? "Listen" : "Listen (Premium)")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userSettings.isPremium ? AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.5))
                            .cornerRadius(25)
                        }
                        
                        Text(story.content)
                            .font(.system(size: userSettings.storyFontSize))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            .lineSpacing(8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Your Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryPurple)
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
}
