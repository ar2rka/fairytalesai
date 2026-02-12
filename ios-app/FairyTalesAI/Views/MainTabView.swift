import SwiftUI

/// Coordinates presenting Create Story from tab bar, "Tonight's Pick", or "Continue Last Night's Adventure" (theme + plot).
final class CreateStoryPresentation: ObservableObject {
    @Published var isPresented = false
    @Published var preselectedTheme: StoryTheme?
    @Published var preselectedPlot: String?
    
    // Story generating page presentation
    @Published var isGeneratingPresented = false
    @Published var generatingParams: StoryGeneratingParams?
    
    func present(withTheme theme: StoryTheme?, plot: String? = nil) {
        preselectedTheme = theme
        preselectedPlot = plot
        isPresented = true
    }
    
    func presentGenerating(params: StoryGeneratingParams) {
        generatingParams = params
        isGeneratingPresented = true
    }
    
    func clearPreselected() {
        preselectedTheme = nil
        preselectedPlot = nil
    }
    
    func clearGenerating() {
        generatingParams = nil
        isGeneratingPresented = false
    }
}

/// Parameters for story generation
struct StoryGeneratingParams: Identifiable, Hashable {
    // Use a stable identity derived from a subset of hashable parameters
    var id: Int { var hasher = Hasher(); self.hash(into: &hasher); return hasher.finalize() }

    let childId: UUID?
    let duration: Int
    let theme: String
    let plot: String?
    let parentId: UUID?
    let children: [Child]
    let language: String

    // Only compare/hash stable, hashable fields. Avoid hashing `children` if `Child` isn't Hashable.
    static func == (lhs: StoryGeneratingParams, rhs: StoryGeneratingParams) -> Bool {
        return lhs.childId == rhs.childId &&
        lhs.duration == rhs.duration &&
        lhs.theme == rhs.theme &&
        lhs.plot == rhs.plot &&
        lhs.parentId == rhs.parentId &&
        lhs.language == rhs.language
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(childId)
        hasher.combine(duration)
        hasher.combine(theme)
        hasher.combine(plot)
        hasher.combine(parentId)
        hasher.combine(language)
    }
}

/// Coordinates navigation between tabs and opening specific stories.
final class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var storyToOpen: UUID? = nil
    
    func switchToLibrary() {
        selectedTab = 1
    }
    
    func switchToLibraryAndOpenStory(_ storyId: UUID) {
        storyToOpen = storyId
        selectedTab = 1
    }
}

struct MainTabView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @StateObject private var createStoryPresentation = CreateStoryPresentation()
    
    var body: some View {
        ZStack {
            // Root background so no tab (especially Library) ever shows black
            AppTheme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            // Content Views — 4 tabs: Home(0), Library(1), Create(2) opens sheet, Profile(3)
            Group {
                if navigationCoordinator.selectedTab == 0 {
                    NavigationView {
                        HomeView()
                    }
                    .id(0)
                } else if navigationCoordinator.selectedTab == 1 {
                    LibraryView()
                    .id(1)
                } else if navigationCoordinator.selectedTab == 3 {
                    NavigationView {
                        SettingsView()
                    }
                    .id(3)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 78) // Space for tab bar
            .environmentObject(createStoryPresentation)
            .environmentObject(navigationCoordinator)

            // 4-tab liquid glass tab bar at the bottom
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $navigationCoordinator.selectedTab, onCreateTapped: {
                    createStoryPresentation.present(withTheme: nil)
                })
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .preferredColorScheme(.dark) // Force dark mode
        .fullScreenCover(isPresented: $createStoryPresentation.isPresented, onDismiss: {
            createStoryPresentation.clearPreselected()
        }) {
            GenerateStoryView(
                preselectedTheme: createStoryPresentation.preselectedTheme,
                preselectedPlot: createStoryPresentation.preselectedPlot
            )
            .environmentObject(childrenStore)
            .environmentObject(storiesStore)
            .environmentObject(premiumManager)
            .environmentObject(userSettings)
            .environmentObject(authService)
            .environmentObject(navigationCoordinator)
            .environmentObject(createStoryPresentation)
        }
        .fullScreenCover(isPresented: $createStoryPresentation.isGeneratingPresented, onDismiss: {
            createStoryPresentation.clearGenerating()
        }) {
            if let params = createStoryPresentation.generatingParams {
                StoryGeneratingView(
                    params: params,
                    storiesStore: storiesStore,
                    userSettings: userSettings,
                    navigationCoordinator: navigationCoordinator
                )
            }
        }
    }
}
