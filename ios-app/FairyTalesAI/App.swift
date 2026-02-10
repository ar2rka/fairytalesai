import SwiftUI
import SwiftData
import UIKit

@main
struct FairyTalesAIApp: App {
    init() {
        // Force Library (and any NavigationStack) to use purple instead of black
        let purple = UIColor(red: 0.12, green: 0.08, blue: 0.22, alpha: 1)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = purple
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UITableView.appearance().backgroundColor = purple
    }
    @StateObject private var childrenStore = ChildrenStore()
    @StateObject private var storiesStore = StoriesStore()
    @StateObject private var premiumManager = PremiumManager()
    @StateObject private var userSettings = UserSettings()
    @StateObject private var authService = AuthService.shared
    @AppStorage("themeMode") private var themeModeRaw = ThemeMode.system.rawValue
    @State private var isInitialLoadComplete = false
    
    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }
    
    // Check if initial auth and children loading is complete
    private var shouldShowLoadingScreen: Bool {
        // Show loading screen while:
        // 1. Auth is resolving (no user yet), OR
        // 2. Initial load hasn't completed (waiting for children to load)
        return authService.currentUser == nil || !isInitialLoadComplete
    }
    
    // SwiftData ModelContainer для кеширования ежедневных историй
    private let modelContainer: ModelContainer = {
        let schema = Schema([DailyFreeStoriesCache.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("SwiftData initialization failed: \(error). Attempting to clear old data...")
            // If the schema has changed, the old store might be incompatible.
            // Since this is just a cache, we can safely delete it and start fresh.
            // SwiftData doesn't expose a direct "delete store" API on the container easily if init fails,
            // but we can try to destroy the persistent store URL if we knew it.
            // Alternatively, failing here usually means we *must* crash or handle it.
            // A common workaround for dev/cache scenarios is to try loading with a new configuration or
            // just let it crash after logging, BUT here we want to auto-recover.
            
            // NOTE: Deleting the store file manually is reliable for file-based stores.
            // Default store is usually at AppSupport/default.store
            // Let's try to construct a container that allows us to recover.
             
             // Simplest recovery for a cache:
             // 1. Log error
             // 2. Try to initialize in-memory if persistent fails (temporary fix for session)
             // 3. OR more aggressively, find the file and delete it.
             
             // Let's implement the file deletion strategy which is most robust for "fix it for good".
             
             // Let's implement the file deletion strategy which is most robust for "fix it for good".
             
             let url = modelConfiguration.url
             try? FileManager.default.removeItem(at: url)
             // Also delete -shm and -wal files if they exist (CoreData/SQLite backing)
             let shmUrl = url.appendingPathExtension("shm")
             let walUrl = url.appendingPathExtension("wal")
             try? FileManager.default.removeItem(at: shmUrl)
             try? FileManager.default.removeItem(at: walUrl)
             
             do {
                 return try ModelContainer(for: schema, configurations: [modelConfiguration])
             } catch {
                 print("SwiftData FATAL initialization error: \(error)")
                 // Fallback to in-memory container so app doesn't crash, but won't persist
                 let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                 return try! ModelContainer(for: schema, configurations: [memoryConfig])
             }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if shouldShowLoadingScreen {
                    // Loading screen - wait for auth and children data to load
                    ZStack {
                        AppTheme.backgroundColor(for: themeMode.colorScheme)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryPurple))
                                .scaleEffect(1.5)
                            
                            Text("Loading...")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textSecondary(for: themeMode.colorScheme))
                        }
                    }
                    .task {
                        // Wait for auth to complete
                        while authService.currentUser == nil {
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        }
                        
                        // Once auth is complete, ensure children are loaded
                        // ChildrenStore automatically loads when currentUser is set via Combine subscription
                        // Wait for the initial load to complete (isLoading becomes false)
                        while childrenStore.isLoading {
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        }
                        
                        // Small delay to ensure children array is populated
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        
                        // Mark initial load as complete
                        isInitialLoadComplete = true
                    }
                    .onChange(of: childrenStore.isLoading) { _, isLoading in
                        // When children finish loading and we have a user, mark complete immediately
                        // This handles the case where loading finishes before the task checks
                        if !isLoading && authService.currentUser != nil && !isInitialLoadComplete {
                            Task {
                                // Small delay to ensure children array is populated
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                isInitialLoadComplete = true
                            }
                        }
                    }
                } else {
                    // Always show main app - anonymous sign-in happens automatically in background
                    // No login screen at startup - users can sign up/login from Settings if needed
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
                }
            }
            .preferredColorScheme(.dark) // Force dark mode globally
        }
    }
}
