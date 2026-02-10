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
        guard !searchText.isEmpty else { return storiesStore.stories }
        return storiesStore.stories.filter { story in
            story.title.localizedCaseInsensitiveContains(searchText) ||
            story.theme.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
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
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .onAppear {
            if let userId = authService.currentUser?.id {
                Task {
                    await storiesStore.loadStoriesFromSupabase(userId: userId)
                }
            }
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
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            TextField(LocalizationManager.shared.librarySearchStories, text: $searchText)
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        }
                        .padding()
                        .background(AppTheme.cardBackground(for: colorScheme))
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Stories List (List нужен для жеста свайпа «удалить»)
                        List {
                            ForEach(filteredStories) { story in
                                NavigationLink(value: story.id) {
                                    StoryLibraryRow(story: story)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task {
                                                    await storiesStore.softDeleteStory(story)
                                                }
                                            } label: {
                                                Label(LocalizationManager.shared.libraryDeleteStory, systemImage: "trash")
                                            }
                                        }
                                        .onAppear {
                                            if searchText.isEmpty,
                                               let index = filteredStories.firstIndex(where: { $0.id == story.id }),
                                               index >= max(0, filteredStories.count - 5),
                                               !storiesStore.isLoadingMore,
                                               storiesStore.hasMoreStories {
                                                Task {
                                                    if let userId = authService.currentUser?.id {
                                                        await storiesStore.loadMoreStories(userId: userId)
                                                    }
                                                }
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if filteredStories.isEmpty {
                                Text(LocalizationManager.shared.libraryNoStoriesFound)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                            
                            if storiesStore.isLoadingMore {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryPurple))
                                    Text(LocalizationManager.shared.libraryLoadingMore)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                }
                                .frame(maxWidth: .infinity)
                                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
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
