import SwiftUI

struct GenerateStoryView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedChildId: UUID? = nil
    @State private var selectedDuration: Double = 3
    @State private var selectedTheme: StoryTheme? = nil
    @State private var plot: String = ""
    @State private var showingStoryResult = false
    @State private var showingPaywall = false
    @State private var generatedStory: Story? = nil
    
    private var maxAllowedDuration: Double {
        userSettings.isPremium ? 30 : 5
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Who is listening?
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Who is listening?")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            if childrenStore.isLoading && childrenStore.children.isEmpty {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryPurple))
                                    Text("Loading children...")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else if childrenStore.children.isEmpty {
                                NavigationLink(destination: AddChildView()) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Add a child first")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.primaryPurple)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(AppTheme.cardBackground(for: colorScheme))
                                    .cornerRadius(16)
                                }
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(childrenStore.children) { child in
                                            ChildSelectionButton(
                                                child: child,
                                                isSelected: selectedChildId == child.id
                                            ) {
                                                selectedChildId = selectedChildId == child.id ? nil : child.id
                                            }
                                        }
                                        
                                        NavigationLink(destination: AddChildView()) {
                                            DashedButton(text: "NEW")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Credit Indicator (for non-premium users)
                        if !userSettings.isPremium {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(AppTheme.primaryPurple)
                                Text("\(userSettings.freeGenerationsRemaining) free story\(userSettings.freeGenerationsRemaining == 1 ? "" : "ies") remaining")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Duration Slider
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Duration")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("\(Int(selectedDuration))")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(AppTheme.primaryPurple)
                                    Text("min")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                }
                                
                                if !userSettings.isPremium && selectedDuration >= 5 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                        Text("Premium")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundColor(.yellow)
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Slider(
                                    value: Binding(
                                        get: { selectedDuration },
                                        set: { newValue in
                                            // If non-premium user tries to go beyond 5 minutes, show paywall
                                            if !userSettings.isPremium && newValue > 5 {
                                                // Show paywall immediately
                                                DispatchQueue.main.async {
                                                    showingPaywall = true
                                                }
                                                // Keep value at 5
                                                selectedDuration = 5
                                            } else {
                                                selectedDuration = newValue
                                            }
                                        }
                                    ),
                                    in: 3...30,
                                    step: 1
                                ) {
                                    Text("Duration")
                                } minimumValueLabel: {
                                    Text("3")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                } maximumValueLabel: {
                                    Text(userSettings.isPremium ? "30" : "30 🔒")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                }
                                .tint(AppTheme.primaryPurple)
                                
                                if !userSettings.isPremium {
                                    HStack {
                                        Text("Free: up to 5 min")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                        
                                        Spacer()
                                        
                                        Text("Premium: up to 30 min")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.primaryPurple)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Theme Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Choose a Theme")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(StoryTheme.allThemes) { theme in
                                    ThemeSelectionButton(
                                        theme: theme,
                                        isSelected: selectedTheme?.id == theme.id
                                    ) {
                                        selectedTheme = selectedTheme?.id == theme.id ? nil : theme
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Brief Plot
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Brief Plot")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            ZStack(alignment: .topLeading) {
                                if plot.isEmpty {
                                    Text("Describe the story you want to create...")
                                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                        .padding()
                                }
                                
                                TextEditor(text: $plot)
                                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(minHeight: 120)
                                    .background(AppTheme.cardBackground(for: colorScheme))
                                    .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Generate Button
                        Button(action: generateStory) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Generate Story")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                canGenerate ?
                                AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.5)
                            )
                            .cornerRadius(25)
                        }
                        .disabled(!canGenerate || storiesStore.isGenerating)
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Умная загрузка: использует кеш если он свежий, иначе обновляет
                await childrenStore.loadChildrenIfNeeded()
            }
            .sheet(isPresented: $showingStoryResult) {
                if let story = generatedStory {
                    StoryResultView(story: story)
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
    
    private var canGenerate: Bool {
        selectedChildId != nil && selectedTheme != nil
    }
    
    private func generateStory() {
        guard let theme = selectedTheme else { return }
        
        let finalDuration = Int(selectedDuration)
        
        // Check if user can generate this story
        if !userSettings.canGenerateStory(duration: finalDuration) {
            // Show paywall if they can't generate
            showingPaywall = true
            return
        }
        
        // Use a free generation if not premium
        if !userSettings.isPremium {
            userSettings.useFreeGeneration()
        }
        
        Task {
            await storiesStore.generateStory(
                childId: selectedChildId,
                length: finalDuration,
                theme: theme.name,
                plot: plot.isEmpty ? nil : plot,
                children: childrenStore.children
            )
            
            await MainActor.run {
                if let latestStory = storiesStore.stories.first {
                    generatedStory = latestStory
                    showingStoryResult = true
                }
            }
        }
    }
}


struct ChildSelectionButton: View {
    let child: Child
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(child.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary(for: colorScheme))
                
                Text(child.ageCategory.shortName)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.textSecondary(for: colorScheme))
            }
            .padding()
            .frame(width: 100)
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(25)
            .overlay(
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
    }
}

struct ThemeSelectionButton: View {
    let theme: StoryTheme
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(theme.emoji)
                    .font(.system(size: 40))
                
                VStack(spacing: 4) {
                    Text(theme.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .white : AppTheme.textPrimary(for: colorScheme))
                    
                    Text(theme.description)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : AppTheme.textSecondary(for: colorScheme))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
    }
}

struct DashedButton: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(AppTheme.primaryPurple)
        .padding()
        .frame(width: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(AppTheme.primaryPurple)
        )
    }
}

struct StoryResultView: View {
    let story: Story
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(story.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
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
                            .cornerRadius(25)
                        }
                        
                        Text(story.content)
                            .font(.system(size: userSettings.storyFontSize))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            .lineSpacing(8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Your Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryPurple)
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
}

