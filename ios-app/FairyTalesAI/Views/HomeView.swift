import SwiftUI

struct HomeView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @Environment(\.colorScheme) var colorScheme
    
    // Hardcoded Free Demo Stories
    private let freeDemoStories: [Story] = [
        Story(
            title: "The Magic Forest Adventure",
            content: "Once upon a time, in a magical forest filled with talking animals and sparkling trees, a brave little explorer discovered a hidden treasure that brought joy to all the creatures.",
            theme: "Adventure",
            duration: 5,
            favoriteStatus: false
        ),
        Story(
            title: "Princess and the Friendly Dragon",
            content: "In a faraway kingdom, a kind princess befriended a dragon who loved to paint rainbows. Together, they showed everyone that friendship knows no boundaries.",
            theme: "Princess",
            duration: 5,
            favoriteStatus: false
        ),
        Story(
            title: "The Space Explorer's Journey",
            content: "A young astronaut traveled through the stars, meeting friendly aliens and discovering planets made of candy. The universe was full of wonder and friendship.",
            theme: "Space",
            duration: 5,
            favoriteStatus: false
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            Text("Create Magical Stories")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Free Demo Stories Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Free Demo Stories")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
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
                        
                        // Main Feature Card
                        NavigationLink(destination: GenerateStoryView()) {
                            FeatureCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        
                        // Who is listening section
                        if !childrenStore.children.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Who is listening?")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                    
                                    Spacer()
                                    
                                    NavigationLink("Manage", destination: ChildrenListView())
                                        .foregroundColor(AppTheme.primaryPurple)
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(childrenStore.children.prefix(3)) { child in
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
                                                Text("Add")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Recent Stories
                        if !storiesStore.stories.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Recent Magic")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                    
                                    Spacer()
                                    
                                    NavigationLink("View All", destination: LibraryView())
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
                            Text("Popular Themes")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(StoryTheme.allThemes.prefix(4)) { theme in
                                    ThemeButton(theme: theme)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    }
                }
            }
        }
    }
    
}

struct FreeDemoStoryCard: View {
    let story: Story
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple.opacity(0.6), AppTheme.accentPurple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(2)
                
                Text("\(story.duration) min • \(story.theme)")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .frame(width: 200)
    }
}

struct FeatureCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("New Feature")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.primaryPurple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryPurple.opacity(0.2))
                    .cornerRadius(AppTheme.cornerRadius)
            }
            
            Text("Spark a New Adventure")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            Text("Create a custom fairy tale instantly with the power of AI magic.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            
            HStack {
                Image(systemName: "sparkles")
                Text("Create New Tale")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "sparkles")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryPurple)
            .cornerRadius(AppTheme.cornerRadius)
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct ChildProfileCircle: View {
    let child: Child
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(child.name.prefix(1).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(child.name)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
        }
    }
}

struct StoryCard: View {
    let story: Story
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple.opacity(0.5), AppTheme.accentPurple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 100)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.7))
                )
            
            Text(story.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .lineLimit(2)
            
            Text("\(story.duration) min • \(story.theme)")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(width: 150)
    }
}

struct ThemeButton: View {
    let theme: StoryTheme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Text(theme.emoji)
                    .font(.system(size: 32))
                
                Text(theme.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
        }
    }
}

struct StoryReadingView: View {
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
                    // Story Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(story.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                Text("\(story.duration) min")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            Text("•")
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            Text(story.theme)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.primaryPurple)
                        }
                    }
                    
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
                    
                    // Story Content
                    Text(story.content)
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        .lineSpacing(12)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
        }
        .navigationTitle("Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
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


