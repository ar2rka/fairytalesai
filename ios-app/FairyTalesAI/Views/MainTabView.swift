import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedTab = 0
    @State private var showingCreateStory = false
    
    var body: some View {
        ZStack {
            // Content Views — 4 tabs: Home(0), Library(1), Create(2) opens sheet, Profile(3)
            Group {
                if selectedTab == 0 {
                    NavigationView {
                        HomeView()
                    }
                    .id(0)
                } else if selectedTab == 1 {
                    NavigationView {
                        LibraryView()
                    }
                    .id(1)
                } else if selectedTab == 3 {
                    NavigationView {
                        SettingsView()
                    }
                    .id(3)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 65) // Space for tab bar

            // 4-tab liquid glass tab bar at the bottom
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, onCreateTapped: {
                    showingCreateStory = true
                })
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .preferredColorScheme(.dark) // Force dark mode
        .fullScreenCover(isPresented: $showingCreateStory) {
            NavigationView {
                GenerateStoryView()
            }
            .environmentObject(childrenStore)
            .environmentObject(storiesStore)
            .environmentObject(premiumManager)
            .environmentObject(userSettings)
            .environmentObject(authService)
        }
    }
}
