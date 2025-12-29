import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @AppStorage("themeMode") private var themeModeRaw = ThemeMode.system.rawValue
    
    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            GenerateStoryView()
                .tabItem {
                    Label("Create", systemImage: "wand.and.stars")
                }
                .tag(1)
            
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .tag(2)
            
            ChildrenListView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(AppTheme.primaryPurple)
        .preferredColorScheme(themeMode.colorScheme)
    }
}


