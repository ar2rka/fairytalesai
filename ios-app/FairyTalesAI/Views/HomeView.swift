import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @Environment(\.colorScheme) var colorScheme
    
    // Hardcoded Free Demo Stories
    private let freeDemoStories: [Story] = [
        Story(
            title: "The Magic Forest Adventure",
            content: "Once upon a time, in a magical forest filled with talking animals and sparkling trees, a brave little explorer discovered a hidden treasure that brought joy to all the creatures.",
            theme: "Fairies",
            duration: 5,
            favoriteStatus: false
        ),
        Story(
            title: "The Pirate's Treasure",
            content: "In a faraway kingdom, a brave pirate captain sailed the seven seas, discovering hidden islands and making friends with sea creatures. Together, they found the greatest treasure of all: friendship.",
            theme: "Pirates",
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
                        
                        // Main Feature Card
                        if childrenStore.hasProfiles {
                        NavigationLink(destination: GenerateStoryView()) {
                            FeatureCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        } else {
                            GetStartedCard()
                                .padding(.horizontal)
                        }
                        
                        // Who is listening section
                        if !childrenStore.children.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Who is listening?")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                    
                                    Spacer()
                                    
                                    NavigationLink("Manage", destination: SettingsView())
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
            }
            .navigationBarTitleDisplayMode(.inline)
<<<<<<< HEAD
=======
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    }
                }
            }
>>>>>>> d586088bf77ddd623d794f3e1676750124dbcf7f
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
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(2)
                    .frame(height: 45, alignment: .topLeading)
                
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
<<<<<<< HEAD

                
                Text("Spark a New Adventure")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Create a custom fairy tale instantly with the power of AI magic.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack {
                    Image(systemName: "sparkles")
=======
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
>>>>>>> d586088bf77ddd623d794f3e1676750124dbcf7f
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

struct GetStartedCard: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @State private var showingAddChild = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Every story needs a hero. Add your child to start the magic!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)
            
            Button(action: { showingAddChild = true }) {
                HStack {
                    Image(systemName: "person.fill.badge.plus")
                    Text("Add Child Profile")
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
            .background(AppTheme.cardBackground)
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
    
    private var themeColor: Color {
        switch theme.name.lowercased() {
        case "space":
            return Color(red: 0.1, green: 0.2, blue: 0.4)
        case "pirates":
            return Color(red: 0.3, green: 0.2, blue: 0.1)
        case "dinosaurs":
            return Color(red: 0.4, green: 0.3, blue: 0.1)
        case "mermaids":
            return Color(red: 0.1, green: 0.3, blue: 0.4)
        case "animals":
            return Color(red: 0.2, green: 0.4, blue: 0.2)
        case "mystery":
            return Color(red: 0.3, green: 0.2, blue: 0.3)
        case "magic school":
            return Color(red: 0.4, green: 0.2, blue: 0.4)
        case "robots":
            return Color(red: 0.3, green: 0.3, blue: 0.3)
        default:
            return AppTheme.primaryPurple
        }
    }
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 6) {
                Text(theme.emoji)
                    .font(.system(size: 28))
                
                Text(theme.name)
<<<<<<< HEAD
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(themeColor.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(themeColor.opacity(0.3), lineWidth: 1)
            )
=======
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardBackground(for: colorScheme))
>>>>>>> d586088bf77ddd623d794f3e1676750124dbcf7f
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
<<<<<<< HEAD
                HStack(spacing: 16) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
=======
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
>>>>>>> d586088bf77ddd623d794f3e1676750124dbcf7f
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

