import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()
    
    var filteredStories: [Story] {
        var seen = Set<UUID>()
        let unique = storiesStore.stories.filter { seen.insert($0.id).inserted }
        guard !searchText.isEmpty else { return unique }
        return unique.filter { story in
            story.title.localizedCaseInsensitiveContains(searchText) ||
            story.theme.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Match the same purple app background used on other tabs
                AppTheme.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                contentView
            }
            .navigationDestination(for: UUID.self) { storyId in
                if let story = storiesStore.stories.first(where: { $0.id == storyId }) {
                    StoryContentView(story: story)
                }
            }
        }
        // Ensure the navigation container itself also uses the themed background,
        // so there are no black flashes behind the content or under the navigation bar.
        .background(
            AppTheme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
        )
    }
    
    private var contentView: some View {
        Group {
            if storiesStore.isLoading {
                loadingView
            } else if storiesStore.stories.isEmpty {
                emptyStateView
            } else {
                storiesListView
            }
        }
        .navigationTitle(LocalizationManager.shared.libraryMyLibrary)
        .navigationBarTitleDisplayMode(.inline)
        // Use the same themed background color for the navigation bar
        // instead of the default black, so Library matches other tabs.
        .toolbarBackground(
            AppTheme.backgroundColor(for: colorScheme),
            for: .navigationBar
        )
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if let userId = authService.currentUser?.id {
                Task {
                    await storiesStore.loadStoriesFromSupabase(userId: userId)
                }
            }
            checkForStoryToOpen()
        }
        .onChange(of: navigationCoordinator.storyToOpen) { _, storyId in
            handleStoryToOpen(storyId)
        }
        .onChange(of: storiesStore.stories.count) { _, _ in
            checkForStoryToOpen()
        }
        .onChange(of: storiesStore.lastGeneratedStoryId) { _, _ in
            checkForStoryToOpen()
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryPurple))
                    .scaleEffect(1.5)
                
                Text(LocalizationManager.shared.libraryLoadingStories)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            }
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                AnimatedBookIcon()
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                
                Text(LocalizationManager.shared.libraryNoStoriesYet)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)
                
                Text(LocalizationManager.shared.libraryCreateFirstStory)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            Spacer()
        }
    }
    
    private var storiesListView: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText, colorScheme: colorScheme)
                .padding(.horizontal)
                .padding(.top)
            StoriesList(
                stories: filteredStories,
                isLoadingMore: storiesStore.isLoadingMore,
                hasMoreStories: storiesStore.hasMoreStories,
                authService: authService,
                onDelete: { story in
                    Task { await storiesStore.softDeleteStory(story) }
                },
                onLoadMore: {
                    Task {
                        if let userId = authService.currentUser?.id {
                            await storiesStore.loadMoreStories(userId: userId)
                        }
                    }
                }
            )
        }
    }
    
    private func handleStoryToOpen(_ storyId: UUID?) {
        guard let storyId = storyId else { return }
        
        func tryOpenStory(attempt: Int = 0) {
            if storiesStore.stories.contains(where: { $0.id == storyId }) {
                navigationPath.append(storyId)
                navigationCoordinator.storyToOpen = nil
            } else if attempt < 10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    tryOpenStory(attempt: attempt + 1)
                }
            } else {
                navigationCoordinator.storyToOpen = nil
            }
        }
        tryOpenStory()
    }
    
    private func checkForStoryToOpen() {
        if let storyId = navigationCoordinator.storyToOpen,
           storiesStore.stories.contains(where: { $0.id == storyId }) {
            navigationPath.append(storyId)
            navigationCoordinator.storyToOpen = nil
        }
    }
    
    private func childName(for childId: UUID?) -> String {
        guard let childId = childId,
              let child = childrenStore.children.first(where: { $0.id == childId }) else {
            return LocalizationManager.shared.libraryUnknown
        }
        return child.name
    }
}

