import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter = "All Stories"
    
    let filters = ["All Stories", "Bedtime", "Adventure", "Fantasy"]
    
    var filteredStories: [Story] {
        var stories = storiesStore.stories
        
        if !searchText.isEmpty {
            stories = stories.filter { story in
                story.title.localizedCaseInsensitiveContains(searchText) ||
                story.theme.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedFilter != "All Stories" {
            stories = stories.filter { $0.theme == selectedFilter }
        }
        
        return stories
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
                            
                            Text("Loading stories...")
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
                            
                            Text("No stories yet")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                .multilineTextAlignment(.center)
                            
                            Text("Create your first magical story")
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
                            
                            TextField("Search stories, characters...", text: $searchText)
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        }
                        .padding()
                        .background(AppTheme.cardBackground(for: colorScheme))
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Filter Bar
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filters, id: \.self) { filter in
                                    FilterButton(
                                        title: filter,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 12)
                        
                        // Stories List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredStories) { story in
                                    StoryLibraryRow(story: story)
                                        .onAppear {
                                            // Загружаем следующую страницу когда показываем последние 5 элементов
                                            // Только если нет фильтров и поиска (работаем с полным списком)
                                            if selectedFilter == "All Stories" && searchText.isEmpty {
                                                if let index = filteredStories.firstIndex(where: { $0.id == story.id }),
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
                                }
                                
                                if filteredStories.isEmpty {
                                    Text("No stories found")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                        .padding()
                                }
                                
                                // Индикатор загрузки для infinite scroll
                                if storiesStore.isLoadingMore {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryPurple))
                                        Text("Loading more stories...")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                    }
                                    .padding()
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("My Library")
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
            return "Unknown"
        }
        return child.name
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : AppTheme.textPrimary(for: colorScheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
        }
    }
}

struct StoryLibraryRow: View {
    let story: Story
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingOptions = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple.opacity(0.5), AppTheme.accentPurple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.7))
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(story.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                HStack {
                    if let childId = story.childId {
                        Text("For: \(childName(for: childId))")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.primaryPurple)
                    }
                    
                    Text("•")
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    
                    Text(timeAgoString(from: story.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                
                HStack(spacing: 8) {
                    // Language
                    if let language = story.language {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                            Text(language.uppercased())
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.cardBackground(for: colorScheme).opacity(0.5))
                        .cornerRadius(6)
                    }
                    
                    // Rating
                    if let rating = story.rating {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("\(rating)/10")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(AppTheme.primaryPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryPurple.opacity(0.2))
                        .cornerRadius(6)
                    }
                }
                
                HStack(spacing: 12) {
                    NavigationLink(destination: StoryContentView(story: story)) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Read")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.primaryPurple)
                    }
                    
                    Text("\(story.duration) min")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
            }
            
            Spacer()
            
            Button(action: { showingOptions = true }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
    }
    
    private func childName(for childId: UUID) -> String {
        childrenStore.children.first(where: { $0.id == childId })?.name ?? "Unknown"
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .weekOfYear, .month], from: date, to: now)
        
        if let days = components.day, days < 7 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let weeks = components.weekOfYear, weeks < 4 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if let months = components.month {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else {
            return "Long ago"
        }
    }
}

struct AnimatedBookIcon: View {
    var body: some View {
        Image(systemName: "book.fill")
            .font(.system(size: 60))
            .frame(width: 80, height: 80) // Fixed frame to prevent layout shifts
    }
}

struct StoryContentView: View {
    let story: Story
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showingPaywall = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(story.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    
                    // Story metadata
                    HStack(spacing: 16) {
                        if let language = story.language {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.system(size: 12))
                                Text(language.uppercased())
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        }
                        
                        if let rating = story.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text("\(rating)/10")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppTheme.primaryPurple)
                        }
                        
                        Text("\(story.duration) min read")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                    
                    Divider()
                        .background(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
                    
                    // Listen Button with Premium Lock
                    Button(action: {
                        if !userSettings.isPremium {
                            showingPaywall = true
                        } else {
                            // Start audio playback
                            // In production, this would start the audio narration
                        }
                    }) {
                        HStack {
                            Image(systemName: userSettings.isPremium ? "play.circle.fill" : "lock.fill")
                            Text(userSettings.isPremium ? "Listen" : "Listen (Premium)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userSettings.isPremium ? AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.5))
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                    
                    // Story content
                    Text(story.content)
                        .font(.system(size: userSettings.storyFontSize))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        .lineSpacing(8)
                }
                .padding()
            }
        }
        .navigationTitle("Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Decrease font size button
                    Button(action: {
                        if userSettings.storyFontSize > 12 {
                            userSettings.storyFontSize -= 2
                        }
                    }) {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundColor(userSettings.storyFontSize > 12 ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    }
                    .disabled(userSettings.storyFontSize <= 12)
                    
                    // Increase font size button
                    Button(action: {
                        if userSettings.storyFontSize < 24 {
                            userSettings.storyFontSize += 2
                        }
                    }) {
                        Image(systemName: "textformat.size.larger")
                            .foregroundColor(userSettings.storyFontSize < 24 ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    }
                    .disabled(userSettings.storyFontSize >= 24)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationView {
                PaywallView()
                    .environmentObject(userSettings)
            }
        }
    }
}


