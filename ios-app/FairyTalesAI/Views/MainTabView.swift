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
            // Content Views
            Group {
                if selectedTab == 0 {
                    HomeView()
                } else if selectedTab == 1 {
                    LibraryView()
                } else if selectedTab == 3 {
                    ExploreView()
                } else if selectedTab == 4 {
                    NavigationView {
                        SettingsView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 65) // Space for TabBar
            
            // Custom Tab Bar at the bottom
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
        .onChange(of: selectedTab) { newValue in
            if newValue == 2 {
                showingCreateStory = true
                // Reset tab to previous after a moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 0
                }
            }
        }
    }
}
