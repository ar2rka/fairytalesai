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

struct FreeDemoStoryCard: View {
    let story: Story
    @Environment(\.colorScheme) var colorScheme
    
    private var themeEmoji: String {
        switch story.theme.lowercased() {
        case "space": return "🚀"
        case "pirates": return "🏴‍☠️"
        case "animals": return "🦁"
        case "fairies": return "🧚"
        case "forest", "adventure": return "🌲"
        case "dragon": return "🐉"
        default: return "📖"
        }
    }
    
    private var themeGradient: [Color] {
        switch story.theme.lowercased() {
        case "space":
            return [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.1, blue: 0.3)]
        case "pirates":
            return [Color(red: 0.3, green: 0.2, blue: 0.1), Color(red: 0.4, green: 0.3, blue: 0.15)]
        case "animals":
            return [Color(red: 0.2, green: 0.4, blue: 0.2), Color(red: 0.15, green: 0.35, blue: 0.15)]
        case "fairies":
            return [Color(red: 0.4, green: 0.2, blue: 0.4), Color(red: 0.5, green: 0.3, blue: 0.5)]
        case "forest", "adventure":
            return [Color(red: 0.1, green: 0.3, blue: 0.2), Color(red: 0.15, green: 0.4, blue: 0.25)]
        case "dragon":
            return [Color(red: 0.4, green: 0.1, blue: 0.1), Color(red: 0.5, green: 0.15, blue: 0.15)]
        default:
            return [AppTheme.primaryPurple.opacity(0.6), AppTheme.accentPurple.opacity(0.6)]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: themeGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 120)
                
                Text(themeEmoji)
                    .font(.system(size: 60))
                
                // Age category badge in top-left corner
                VStack {
                    HStack {
                        Text(story.ageCategory)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.4))
                            )
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(2)
                    .frame(height: 45, alignment: .topLeading)
                
                Text("\(story.duration) min • \(story.theme)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.85)) // Lighter for better contrast
            }
        }
        .frame(width: 200)
    }
}

struct FeatureCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.homeSparkNewAdventure)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            Text("Create a custom fairy tale instantly with the power of AI magic.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            
            HStack {
                Image(systemName: "sparkles")
                Text(LocalizationManager.shared.homeCreateNewTale)
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

struct GetStartedCard: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddChild = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.homeEveryStoryNeedsHero)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .multilineTextAlignment(.leading)
            
            Button(action: { showingAddChild = true }) {
                HStack {
                    Image(systemName: "person.fill.badge.plus")
                    Text(LocalizationManager.shared.homeAddChildProfile)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
        .sheet(isPresented: $showingAddChild) {
            AddChildView()
        }
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
                .frame(height: 40, alignment: .topLeading) // Fixed height for alignment
            
            Text("\(story.duration) \(LocalizationManager.shared.generateStoryMin) • \(LocalizationManager.shared.localizedThemeName(story.theme))")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.85)) // Lighter for better contrast
        }
        .frame(width: 150)
    }
}

struct ThemeButton: View {
    let theme: StoryTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var isSelected = false
    @State private var bounceScale: CGFloat = 1.0
    
    private var themeColor: Color {
        switch theme.name.lowercased() {
        case "space":
            return Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
        case "pirates":
            return Color(red: 0.8, green: 0.6, blue: 0.2) // Gold
        case "dinosaurs":
            return Color(red: 0.2, green: 0.8, blue: 0.2) // Green
        case "mermaids":
            return Color(red: 0.2, green: 0.6, blue: 1.0) // Blue
        case "animals":
            return Color(red: 0.4, green: 0.7, blue: 0.3) // Green
        case "mystery":
            return Color(red: 0.6, green: 0.3, blue: 0.8) // Purple
        case "magic school":
            return Color(red: 0.8, green: 0.3, blue: 0.8) // Magenta
        case "robots":
            return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        default:
            return AppTheme.primaryPurple
        }
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Toggle selection
            isSelected.toggle()
            
            // Bounce animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounceScale = 1.2
            }
            
            // Reset bounce
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceScale = 1.0
                }
            }
        }) {
            VStack(spacing: 6) {
                Text(theme.emoji)
                    .font(.system(size: 28))
                
                Text(theme.localizedName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(themeColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isSelected ? themeColor : themeColor.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .shadow(
                        color: isSelected ? themeColor.opacity(0.6) : .clear,
                        radius: isSelected ? 8 : 0
                    )
            )
            .cornerRadius(AppTheme.cornerRadius)
            .scaleEffect(bounceScale)
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
    @State private var showShareSheet = false
    
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
                                Text(userSettings.isPremium ? LocalizationManager.shared.storyReadingListen : LocalizationManager.shared.storyReadingListenPremium)
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
        .navigationTitle(LocalizationManager.shared.storyReadingStory)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    }
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationView {
                PaywallView()
                    .environmentObject(userSettings)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [
                "\(story.title)\n\n\(story.content)"
            ])
        }
    }
}

struct ProfileSwitcherButton: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @State private var showingChildPicker = false
    
    var body: some View {
        if let firstChild = childrenStore.children.first {
            Button(action: { showingChildPicker = true }) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(firstChild.name.prefix(1).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .sheet(isPresented: $showingChildPicker) {
                ChildPickerView()
                    .environmentObject(childrenStore)
            }
        } else {
            NavigationLink(destination: SettingsView()) {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textPrimary)
                    )
            }
        }
    }
}

struct ChildPickerView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.darkPurple.ignoresSafeArea()
                
                if childrenStore.children.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("No children added yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("Add a child profile in Settings")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                } else {
                    List {
                        ForEach(childrenStore.children) { child in
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(child.name.prefix(1).uppercased())
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(child.name)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Text(child.ageCategory.displayName)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismiss()
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryPurple)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

