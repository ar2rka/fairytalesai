import SwiftUI
import SwiftData

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
    
    // SwiftData ModelContainer для кеширования ежедневных историй
    private let modelContainer: ModelContainer = {
        let schema = Schema([DailyFreeStoriesCache.self, CachedStory.self])
        let configuration = ModelConfiguration(schema: schema)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    
    var body: some Scene {
        WindowGroup {
            Group {
                // Always show main app - anonymous sign-in happens automatically in background
                // No login screen at startup - users can sign up/login from Settings if needed
                if userSettings.hasCompletedOnboarding && userSettings.onboardingComplete {
                    MainTabView()
                        .environmentObject(childrenStore)
                        .environmentObject(storiesStore)
                        .environmentObject(premiumManager)
                        .environmentObject(userSettings)
                        .environmentObject(authService)
                        .modelContainer(modelContainer)
                        .preferredColorScheme(.dark) // Force dark mode for bedtime-friendly UI
                        .onAppear {
                            premiumManager.syncWithUserSettings(userSettings)
                        }
                } else {
                    OnboardingView()
                        .environmentObject(userSettings)
                        .environmentObject(authService)
                        .modelContainer(modelContainer)
                        .preferredColorScheme(.dark)
                }
            }
            .preferredColorScheme(.dark) // Force dark mode globally
        }
    }
}
