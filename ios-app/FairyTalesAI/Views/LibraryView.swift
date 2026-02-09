import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    
    var filteredStories: [Story] {
        guard !searchText.isEmpty else { return storiesStore.stories }
        return storiesStore.stories.filter { story in
            story.title.localizedCaseInsensitiveContains(searchText) ||
            story.theme.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                    if storiesStore.isLoading {
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
                    } else if storiesStore.stories.isEmpty {
                        // Empty State
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
                    } else {
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
    }
    
    private func childName(for childId: UUID?) -> String {
        guard let childId = childId,
              let child = childrenStore.children.first(where: { $0.id == childId }) else {
            return LocalizationManager.shared.libraryUnknown
        }
        return child.name
    }
}
