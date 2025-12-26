import SwiftUI

@main
struct FairyTalesAIApp: App {
    @StateObject private var childrenStore = ChildrenStore()
    @StateObject private var storiesStore = StoriesStore()
    @StateObject private var premiumManager = PremiumManager()
    @StateObject private var userSettings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            if userSettings.hasCompletedOnboarding && userSettings.onboardingComplete {
                MainTabView()
                    .environmentObject(childrenStore)
                    .environmentObject(storiesStore)
                    .environmentObject(premiumManager)
                    .environmentObject(userSettings)
                    .preferredColorScheme(.dark)
                    .onAppear {
                        premiumManager.syncWithUserSettings(userSettings)
                    }
            } else {
                OnboardingView()
                    .environmentObject(userSettings)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
