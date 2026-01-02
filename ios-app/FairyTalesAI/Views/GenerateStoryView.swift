import SwiftUI

struct GenerateStoryView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var viewModel = GenerateStoryViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                if !childrenStore.hasProfiles {
                    // Empty State
                    VStack(spacing: 24) {
                        Image(systemName: "person.fill.badge.plus")
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(AppTheme.primaryPurple.opacity(0.6))
                            .symbolEffect(.pulse, options: .repeating)
                        
                        Text("Who is the hero today?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
                        Text("You need to add a child profile before we can craft a tale.")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: { viewModel.showingAddChild = true }) {
                            HStack {
                                Image(systemName: "person.fill.badge.plus")
                                Text("Create a Profile")
                                    .font(.system(size: 18, weight: .semibold))
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
                        .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 32) {
                            childrenSelectionSection
                            
                            if !userSettings.isPremium {
                                creditsIndicator
                            }
                            
                            durationSection
                            
                            themeSelectionSection
                            
                            plotSection
                            
                            generateButton
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await childrenStore.loadChildrenIfNeeded()
            }
            .sheet(isPresented: $viewModel.showingAddChild) {
                AddChildView()
            }
            .sheet(isPresented: $viewModel.showingStoryResult) {
                if let story = viewModel.generatedStory {
                    StoryResultView(story: story)
                }
            }
            .sheet(isPresented: $viewModel.showingPaywall) {
                NavigationView {
                    PaywallView()
                        .environmentObject(userSettings)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var childrenSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who is listening?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            if childrenStore.isLoading && childrenStore.children.isEmpty {
                loadingView
            } else if childrenStore.children.isEmpty {
                addFirstChildButton
            } else {
                childrenList
            }
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryPurple))
            Text("Loading children...")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var addFirstChildButton: some View {
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
    }
    
    private var childrenList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(childrenStore.children) { child in
                    ChildSelectionButton(
                        child: child,
                        isSelected: viewModel.selectedChildId == child.id
                    ) {
                        viewModel.selectedChildId = viewModel.selectedChildId == child.id ? nil : child.id
                    }
                }
                
                NavigationLink(destination: AddChildView()) {
                    DashedButton(text: "NEW")
                }
            }
        }
    }
    
    private var creditsIndicator: some View {
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
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Duration")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(Int(viewModel.selectedDuration))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primaryPurple)
                    Text("min")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                
                if !userSettings.isPremium && viewModel.selectedDuration >= 5 {
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
                        get: { viewModel.selectedDuration },
                        set: { viewModel.validateDuration(newValue: $0, isPremium: userSettings.isPremium) }
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
    }
    
    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Theme")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(StoryTheme.allThemes) { theme in
                    ThemeSelectionButton(
                        theme: theme,
                        isSelected: viewModel.selectedTheme?.id == theme.id
                    ) {
                        viewModel.selectedTheme = viewModel.selectedTheme?.id == theme.id ? nil : theme
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var plotSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Brief Plot")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            ZStack(alignment: .topLeading) {
                if viewModel.plot.isEmpty {
                    Text("Describe the story you want to create...")
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        .padding()
                }
                
                TextEditor(text: $viewModel.plot)
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 120)
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .cornerRadius(25)
            }
        }
        .padding(.horizontal)
    }
    
    private var generateButton: some View {
        Button(action: {
            viewModel.generateStory(
                userSettings: userSettings,
                storiesStore: storiesStore,
                childrenStore: childrenStore
            )
        }) {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Generate Story")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.canGenerate && !storiesStore.isGenerating ?
                AppTheme.primaryPurple : AppTheme.primaryPurple.opacity(0.5)
            )
            .cornerRadius(25)
        }
        .disabled(!viewModel.canGenerate || storiesStore.isGenerating)
        .padding(.horizontal)
        .padding(.bottom, 100)
    }
}
