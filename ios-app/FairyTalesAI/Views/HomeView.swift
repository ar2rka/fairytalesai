import SwiftUI
import UIKit
import SwiftData

// MARK: - Instrumentation PreferenceKey (shared with ExploreView)
struct ContentMinYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

struct HomeView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var freeDemoStories: [Story] = []
    @State private var isLoadingFreeStories = false
    
    private let storiesService = StoriesService.shared
    
    // Фильтруем детей, оставляя только тех, у кого есть userId (из Supabase)
    private var supabaseChildren: [Child] {
        childrenStore.children.filter { $0.userId != nil }
    }

    /// Selected child (from "Who is listening?").
    private var selectedChild: Child? {
        guard let id = childrenStore.selectedChildId else { return nil }
        return childrenStore.children.first { $0.id == id }
    }

    /// Stories that belong to the selected child.
    private var childStoriesForSelected: [Story] {
        guard let childId = childrenStore.selectedChildId else { return [] }
        return storiesStore.stories.filter { $0.childId == childId }
    }

    private static let recentStoryInterval: TimeInterval = 7 * 24 * 60 * 60

    /// Most recent story for the selected child that is within the last 7 days (for "Continue Last Night's Adventure").
    private var recentStoryForSelectedChild: Story? {
        let sevenDaysAgo = Date().addingTimeInterval(-Self.recentStoryInterval)
        return childStoriesForSelected
            .filter { $0.createdAt > sevenDaysAgo }
            .max(by: { $0.createdAt < $1.createdAt })
    }

    /// Visibility rule: show button only when selected child has at least one story from the last 7 days, and story data has loaded.
    private var shouldShowContinueButton: Bool {
        let child = selectedChild
        let stories = childStoriesForSelected
        let mostRecent = recentStoryForSelectedChild

        #if DEBUG
        print("🔍 Continue Button Check:")
        print("  - Selected child: \(child?.name ?? "none")")
        print("  - Stories count: \(stories.count)")
        print("  - Most recent story date: \(mostRecent.map { "\($0.createdAt)" } ?? "none")")
        #endif

        // Rule 1: Must have a selected child
        guard let _ = child else {
            #if DEBUG
            print("  - ❌ No child selected")
            #endif
            return false
        }

        // Rule 2: Don't evaluate until story data has loaded (avoids race condition)
        if storiesStore.isLoading {
            #if DEBUG
            print("  - ⏳ Stories still loading")
            #endif
            return false
        }

        // Rule 3: Must have at least one story in the last 7 days for that child
        guard mostRecent != nil else {
            #if DEBUG
            print("  - ❌ No recent stories for \(child?.name ?? "child")")
            #endif
            return false
        }

        #if DEBUG
        print("  - ✅ Button visible")
        #endif
        return true
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Welcome Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationManager.shared.homeWelcome)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(white: 0.85))
                            
                            Text(LocalizationManager.shared.homeCreateMagicalStories)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        }
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .background(
                            GeometryReader { headerGeo in
                                Color.clear.preference(
                                    key: ContentMinYPreferenceKey.self,
                                    value: headerGeo.frame(in: .named("scroll")).minY
                                )
                            }
                        )
                        
                        // 2. Who is listening? (moved up)
                        whoIsListeningSection
                        
                        // 3. Daily Free Story
                        if !freeDemoStories.isEmpty || isLoadingFreeStories {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(LocalizationManager.shared.homeDailyFreeStory)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                    .padding(.horizontal)
                                
                                if isLoadingFreeStories {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding()
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(alignment: .top, spacing: 16) {
                                            ForEach(freeDemoStories) { story in
                                                NavigationLink(destination: StoryReadingView(story: story)) {
                                                    FreeDemoStoryCard(story: story)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        
                        // Recent Stories
                        if !storiesStore.stories.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(LocalizationManager.shared.homeRecentMagic)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                    
                                    Spacer()
                                    
                                    NavigationLink(LocalizationManager.shared.homeViewAll, destination: LibraryView())
                                        .foregroundColor(AppTheme.primaryPurple)
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(storiesStore.stories.prefix(5)) { story in
                                            StoryCard(story: story)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // 4. Tonight's Pick (single recommendation)
                        tonightsPickSection
                        
                        // Continue Last Night's Adventure (only if selected child has a story in last 7 days)
                        if shouldShowContinueButton {
                            continueStoryButton
                        }
                    }
                    .padding(.bottom, 100)
                    
                    // Bottom spacing for TabBar
                    Spacer(minLength: 50)
                }
                .coordinateSpace(name: "scroll")
            }
        }
        .navigationTitle(LocalizationManager.shared.tabHome)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .task {
            await loadDailyFreeStories()
        }
    }
    
    // MARK: - Sections

    private var whoIsListeningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizationManager.shared.homeWhoIsListening)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                Spacer()
                
                NavigationLink(destination: NavigationView { SettingsView() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 21))
                        .foregroundColor(AppTheme.primaryPurple)
                }
            }
            .padding(.horizontal)
            
            if !supabaseChildren.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(supabaseChildren.prefix(3)) { child in
                            Button {
                                childrenStore.selectedChildId = childrenStore.selectedChildId == child.id ? nil : child.id
                            } label: {
                                ChildProfileCircle(child: child, isSelected: childrenStore.selectedChildId == child.id)
                            }
                            .buttonStyle(ChildSelectionButtonStyle())
                        }
                        
                        NavigationLink(destination: AddChildView()) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(AppTheme.primaryPurple, lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 22))
                                                .foregroundColor(AppTheme.primaryPurple)
                                        )
                                }
                                .frame(width: 56, height: 56)
                                Text(LocalizationManager.shared.homeAdd)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            }
                            .padding(6)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.primaryPurple.opacity(0.6))
                    
                    Text(LocalizationManager.shared.homeWhoIsOurHero)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    
                    Text(LocalizationManager.shared.homeAddProfileDescription)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                    
                    NavigationLink(destination: AddChildView()) {
                        HStack {
                            Image(systemName: "plus")
                            Text(LocalizationManager.shared.homeAddProfile)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppTheme.primaryPurple)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .padding(.horizontal)
            }
        }
    }

    private var tonightsPickSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationManager.shared.homeTonightsPick)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .padding(.horizontal)
            
            TonightsPickCard(theme: StoryTheme.tonightsPick)
                .padding(.horizontal)
        }
    }

    private var continueStoryButton: some View {
        Group {
            if let story = recentStoryForSelectedChild {
                NavigationLink(destination: StoryReadingView(story: story)) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text(LocalizationManager.shared.homeContinueLastNight)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .fill(AppTheme.primaryPurple.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(AppTheme.primaryPurple.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: AppTheme.primaryPurple.opacity(0.25), radius: 8, x: 0, y: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }

    private func loadDailyFreeStories() async {
        isLoadingFreeStories = true
        defer { isLoadingFreeStories = false }
        
        do {
            let stories = try await storiesService.fetchDailyFreeStories(modelContext: modelContext)
            freeDemoStories = stories
        } catch {
            print("❌ Ошибка загрузки ежедневных бесплатных историй: \(error.localizedDescription)")
            // В случае ошибки пытаемся загрузить из кеша
            if let cachedStories = DailyFreeStoriesCacheService.shared.getCachedStories(modelContext: modelContext) {
                freeDemoStories = cachedStories
            } else {
                freeDemoStories = []
            }
        }
    }
}
