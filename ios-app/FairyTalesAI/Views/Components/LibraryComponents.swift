import SwiftUI

/// Reusable search bar with magnifying glass icon.
struct SearchBar: View {
    @Binding var text: String
    var colorScheme: ColorScheme

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            TextField(LocalizationManager.shared.librarySearchStories, text: $text)
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
    }
}

/// Stories list with swipe-to-delete and infinite scroll.
struct StoriesList: View {
    let stories: [Story]
    let isLoadingMore: Bool
    let hasMoreStories: Bool
    let authService: AuthService
    var onDelete: (Story) -> Void
    var onLoadMore: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            ForEach(stories) { story in
                StoryRowLink(story: story,
                             stories: stories,
                             authService: authService,
                             onDelete: onDelete,
                             onLoadMore: onLoadMore)
            }

            if stories.isEmpty {
                EmptySearchRow()
            }

            if isLoadingMore {
                LoadingMoreRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct StoryRowLink: View {
    let story: Story
    let stories: [Story]
    let authService: AuthService
    var onDelete: (Story) -> Void
    var onLoadMore: () -> Void

    var body: some View {
        NavigationLink(value: story.id) {
            StoryLibraryRow(story: story)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .onAppear {
            guard let idx = stories.firstIndex(where: { $0.id == story.id }) else { return }
            if idx >= max(0, stories.count - 5) {
                onLoadMore()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete(story)
            } label: {
                Label(LocalizationManager.shared.libraryDeleteStory, systemImage: "trash")
            }
        }
    }
}

struct EmptySearchRow: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(LocalizationManager.shared.libraryNoStoriesFound)
            .font(.system(size: 16))
            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

struct LoadingMoreRow: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
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
