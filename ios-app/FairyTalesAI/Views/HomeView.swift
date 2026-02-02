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
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Welcome Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationManager.shared.homeWelcome)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(white: 0.85)) // Lighter for better contrast
                            
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
                        
                        // Free Demo Stories Section
                        if !freeDemoStories.isEmpty || isLoadingFreeStories {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(LocalizationManager.shared.homeFreeStories)
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
                        
                        // Who is listening section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(LocalizationManager.shared.homeWhoIsListening)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                
                                Spacer()
                                
                                NavigationLink(LocalizationManager.shared.homeManage, destination: NavigationView { SettingsView() })
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                            .padding(.horizontal)
                            
                            if !supabaseChildren.isEmpty {
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(supabaseChildren.prefix(3)) { child in
                                            ChildProfileCircle(child: child)
                                        }
                                        
                                        NavigationLink(destination: AddChildView()) {
                                            VStack {
                                                Circle()
                                                    .strokeBorder(AppTheme.primaryPurple, lineWidth: 2)
                                                    .frame(width: 60, height: 60)
                                                    .overlay(
                                                        Image(systemName: "plus")
                                                            .foregroundColor(AppTheme.primaryPurple)
                                                    )
                                                Text(LocalizationManager.shared.homeAdd)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                // Empty state for children
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
                        
                        // Popular Themes
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.homePopularThemes)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(StoryTheme.allThemes) { theme in
                                    ThemeButton(theme: theme)
                                }
                            }
                            .padding(.horizontal)
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
