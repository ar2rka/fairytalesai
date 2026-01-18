import SwiftUI

@main
struct FairyTalesAIApp: App {
    @StateObject private var childrenStore = ChildrenStore()
    @StateObject private var storiesStore = StoriesStore()
    @StateObject private var premiumManager = PremiumManager()
    @StateObject private var userSettings = UserSettings()
    @StateObject private var authService = AuthService.shared
    @AppStorage("themeMode") private var themeModeRaw = ThemeMode.system.rawValue
    
    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                // If authenticated, show main app
                if authService.isAuthenticated {
                    if userSettings.hasCompletedOnboarding && userSettings.onboardingComplete {
                        MainTabView()
                            .environmentObject(childrenStore)
                            .environmentObject(storiesStore)
                            .environmentObject(premiumManager)
                            .environmentObject(userSettings)
                            .environmentObject(authService)
                            .preferredColorScheme(.dark) // Force dark mode for bedtime-friendly UI
                            .onAppear {
                                premiumManager.syncWithUserSettings(userSettings)
                            }
                    } else {
                        OnboardingView()
                            .environmentObject(userSettings)
                            .environmentObject(authService)
                            .preferredColorScheme(.dark)
                    }
                } else if authService.isGuest {
                    // Guest mode - show main app without authentication
                    if userSettings.hasCompletedOnboarding && userSettings.onboardingComplete {
                        MainTabView()
                            .environmentObject(childrenStore)
                            .environmentObject(storiesStore)
                            .environmentObject(premiumManager)
                            .environmentObject(userSettings)
                            .environmentObject(authService)
                            .preferredColorScheme(.dark) // Force dark mode for bedtime-friendly UI
                            .onAppear {
                                premiumManager.syncWithUserSettings(userSettings)
                            }
                    } else {
                        OnboardingView()
                            .environmentObject(userSettings)
                            .environmentObject(authService)
                            .preferredColorScheme(.dark)
                    }
                } else {
                    // Not authenticated and not in guest mode - show login
                    LoginView()
                        .environmentObject(authService)
                        .preferredColorScheme(.dark)
                }
            }
            .preferredColorScheme(.dark) // Force dark mode globally
        }
    }
}
