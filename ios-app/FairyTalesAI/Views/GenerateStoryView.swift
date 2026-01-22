import SwiftUI

struct GenerateStoryView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
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
                        
                        Text(LocalizationManager.shared.generateStoryWhoIsHeroToday)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
                        Text(LocalizationManager.shared.generateStoryNeedProfile)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button(action: { viewModel.showingAddChild = true }) {
                            HStack {
                                Image(systemName: "person.fill.badge.plus")
                                Text(LocalizationManager.shared.generateStoryCreateProfile)
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
                            
                            durationSection
                            
                            themeSelectionSection
                            
                            plotSection
                            
                            // Отображение ошибок
                            if let errorMessage = storiesStore.errorMessage {
                                errorAlertView(message: errorMessage)
                            }
                            
                            generateButton
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.generateStoryCreateStory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                }
            }
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
        }
    }
    
    // MARK: - Subviews
    
    private var childrenSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.generateStoryWhoIsListening)
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
            Text(LocalizationManager.shared.generateStoryLoadingChildren)
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
                Text(LocalizationManager.shared.generateStoryAddChildFirst)
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
                    DashedButton(text: LocalizationManager.shared.generateStoryNew)
                }
            }
        }
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(LocalizationManager.shared.generateStoryDuration)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(Int(viewModel.selectedDuration))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primaryPurple)
                    Text(LocalizationManager.shared.generateStoryMin)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
            }
            
            VStack(spacing: 8) {
                Slider(
                    value: $viewModel.selectedDuration,
                    in: 3...5,
                    step: 1
                ) {
                    Text(LocalizationManager.shared.generateStoryDuration)
                } minimumValueLabel: {
                    Text("3")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                } maximumValueLabel: {
                    Text("5")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                .tint(AppTheme.primaryPurple)
            }
        }
        .padding(.horizontal)
    }
    
    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.generateStoryChooseTheme)
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
            Text(LocalizationManager.shared.generateStoryBriefPlot)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            ZStack(alignment: .topLeading) {
                if viewModel.plot.isEmpty {
                    Text(LocalizationManager.shared.generateStoryDescribeStory)
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
            // Очищаем предыдущую ошибку перед новой попыткой
            storiesStore.errorMessage = nil
            viewModel.generateStory(
                userSettings: userSettings,
                storiesStore: storiesStore,
                childrenStore: childrenStore
            )
        }) {
            HStack {
                if storiesStore.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(storiesStore.isGenerating ? LocalizationManager.shared.generateStoryGenerating : LocalizationManager.shared.generateStoryGenerateStory)
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
    
    private func errorAlertView(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 20))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: {
                storiesStore.errorMessage = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
