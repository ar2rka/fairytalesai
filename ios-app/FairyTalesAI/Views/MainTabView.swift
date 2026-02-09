import SwiftUI

/// Coordinates presenting Create Story from tab bar, "Tonight's Pick", or "Continue Last Night's Adventure" (theme + plot).
final class CreateStoryPresentation: ObservableObject {
    @Published var isPresented = false
    @Published var preselectedTheme: StoryTheme?
    @Published var preselectedPlot: String?
    func present(withTheme theme: StoryTheme?, plot: String? = nil) {
        preselectedTheme = theme
        preselectedPlot = plot
        isPresented = true
    }
    func clearPreselected() {
        preselectedTheme = nil
        preselectedPlot = nil
    }
}

struct MainTabView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedTab = 0
    @StateObject private var createStoryPresentation = CreateStoryPresentation()
    
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
            .environmentObject(createStoryPresentation)

            // 4-tab liquid glass tab bar at the bottom
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, onCreateTapped: {
                    createStoryPresentation.present(withTheme: nil)
                })
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .preferredColorScheme(.dark) // Force dark mode
        .fullScreenCover(isPresented: $createStoryPresentation.isPresented, onDismiss: {
            createStoryPresentation.clearPreselected()
        }) {
            NavigationView {
                GenerateStoryView(
                    preselectedTheme: createStoryPresentation.preselectedTheme,
                    preselectedPlot: createStoryPresentation.preselectedPlot
                )
            }
            .environmentObject(childrenStore)
            .environmentObject(storiesStore)
            .environmentObject(premiumManager)
            .environmentObject(userSettings)
            .environmentObject(authService)
        }
    }
}
