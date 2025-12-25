import SwiftUI

struct HomeView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.darkPurple.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(greeting)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text("Good Evening, Storyteller")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                        
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
                                        .foregroundColor(AppTheme.textPrimary)
                                    
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
                                                    .foregroundColor(AppTheme.textSecondary)
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
                                        .foregroundColor(AppTheme.textPrimary)
                                    
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
                                .foregroundColor(AppTheme.textPrimary)
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
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 18 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }
}

struct FeatureCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("New Feature")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.primaryPurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AppTheme.primaryPurple.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Text("Spark a New Adventure")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Create a custom fairy tale instantly with the power of AI magic.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack {
                    Image(systemName: "sparkles")
                    Image(systemName: "sparkles")
                    Text("Create New Tale")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primaryPurple)
                .cornerRadius(16)
            }
            .padding()
            .background(AppTheme.cardBackground)
        }
        .cornerRadius(24)
    }
}

struct ChildProfileCircle: View {
    let child: Child
    
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
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

struct StoryCard: View {
    let story: Story
    
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
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)
            
            Text("\(story.length) min • \(story.theme)")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(width: 150)
    }
}

struct ThemeButton: View {
    let theme: StoryTheme
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Text(theme.emoji)
                    .font(.system(size: 32))
                
                Text(theme.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
        }
    }
}

