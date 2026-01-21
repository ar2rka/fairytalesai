import SwiftUI

struct StoryResultView: View {
    let story: Story
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    @State private var showingPaywall = false
    
    private var soonText: String {
        selectedLanguage == "Russian" ? "Скоро" : "Soon"
    }
    
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
                            HStack(spacing: 12) {
                                Image(systemName: userSettings.isPremium ? "play.circle.fill" : "lock.fill")
                                Text(userSettings.isPremium ? "Listen" : "Listen (Premium)")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Spacer()
                                
                                // Soon badge
                                Text(soonText)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(8)
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
