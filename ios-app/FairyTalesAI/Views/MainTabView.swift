import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ChildrenListView()
                .tabItem {
                    Label("Children", systemImage: "person.2.fill")
                }
                .tag(1)
            
            GenerateStoryView()
                .tabItem {
                    Image(systemName: "sparkles")
                        .symbolEffect(.pulse)
                }
                .tag(2)
            
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(AppTheme.primaryPurple)
        .preferredColorScheme(.dark)
    }
}

