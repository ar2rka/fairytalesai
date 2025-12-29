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
                if !authService.isAuthenticated {
                    LoginView()
                        .environmentObject(authService)
                        .preferredColorScheme(themeMode.colorScheme)
                } else if userSettings.hasCompletedOnboarding && userSettings.onboardingComplete {
                    MainTabView()
                        .environmentObject(childrenStore)
                        .environmentObject(storiesStore)
                        .environmentObject(premiumManager)
                        .environmentObject(userSettings)
                        .environmentObject(authService)
                        .preferredColorScheme(themeMode.colorScheme)
                        .onAppear {
                            premiumManager.syncWithUserSettings(userSettings)
                        }
                } else {
                    OnboardingView()
                        .environmentObject(userSettings)
                        .environmentObject(authService)
                        .preferredColorScheme(themeMode.colorScheme)
                }
            }
            .preferredColorScheme(themeMode.colorScheme)
        }
    }
}
