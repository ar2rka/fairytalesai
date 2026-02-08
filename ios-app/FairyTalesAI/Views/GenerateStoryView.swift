import SwiftUI

struct GenerateStoryView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel = GenerateStoryViewModel()
    @State private var showDisabledGenerateAlert = false
    @State private var showAllThemes = false
    
    /// When opening from "Tonight's Pick" on Home, this theme is preselected.
    var preselectedTheme: StoryTheme? = nil
    
    var body: some View {
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
                    VStack(spacing: 24) {
                        childrenSelectionSection
                        
                        durationSection
                        
                        themeSelectionSection
                        
                        seeAllThemesButton
                        
                        plotSection
                        
                        // Отображение ошибок
                        if let errorMessage = storiesStore.errorMessage {
                            errorAlertView(message: errorMessage)
                        }
                        
                        generateButton
                    }
                }
                .contentMargins(.top, 0, for: .scrollContent)
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
        .onAppear {
            if childrenStore.children.count == 1 {
                viewModel.selectedChildId = childrenStore.children.first?.id
            }
            if let theme = preselectedTheme {
                viewModel.selectedTheme = theme
            }
        }
        .onChange(of: childrenStore.children.count) { _, newCount in
            if newCount == 1 {
                viewModel.selectedChildId = childrenStore.children.first?.id
            }
        }
        .sheet(isPresented: $viewModel.showingAddChild) {
            AddChildView()
        }
        .sheet(isPresented: $viewModel.showingStoryResult, onDismiss: {
            dismiss()
        }) {
            if let story = viewModel.generatedStory {
                StoryResultView(story: story)
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
    
    private var selectedChildForThemes: Child? {
        guard let id = viewModel.selectedChildId else { return nil }
        return childrenStore.children.first { $0.id == id }
    }

    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizationManager.shared.generateStoryChooseTheme)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            if showAllThemes {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(StoryTheme.allThemes, id: \.name) { theme in
                        ThemeSelectionButton(
                            theme: theme,
                            isSelected: viewModel.selectedTheme?.name == theme.name
                        ) {
                            viewModel.selectedTheme = viewModel.selectedTheme?.name == theme.name ? nil : theme
                        }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(StoryTheme.visibleThemes(for: selectedChildForThemes), id: \.name) { theme in
                        ThemeSelectionButton(
                            theme: theme,
                            isSelected: viewModel.selectedTheme?.name == theme.name
                        ) {
                            viewModel.selectedTheme = viewModel.selectedTheme?.name == theme.name ? nil : theme
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var seeAllThemesButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                showAllThemes.toggle()
            }
        }) {
            HStack(spacing: 4) {
                if showAllThemes {
                    Text(LocalizationManager.shared.generateStoryShowLess)
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                } else {
                    Text(LocalizationManager.shared.generateStorySeeAllThemes)
                    Text(LocalizationManager.shared.generateStoryMoreThemes)
                        .foregroundColor(Color(white: 0.55))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppTheme.primaryPurple)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal)
        .padding(.top, 2)
    }
    
    private var plotSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.generateStoryBriefPlot)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.plot)
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 120)
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .cornerRadius(25)
                    .overlay(alignment: .topLeading) {
                        if viewModel.plot.isEmpty {
                            Text(LocalizationManager.shared.generateStoryPlotPlaceholder)
                                .font(.system(size: 16, weight: .regular))
                                .italic()
                                .foregroundColor(Color(red: 0.72, green: 0.75, blue: 0.8)) // Lighter gray - visible on dark card
                                .multilineTextAlignment(.leading)
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .padding(.horizontal)
    }
    
    private var generateButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                if !viewModel.canGenerate {
                    showDisabledGenerateAlert = true
                    return
                }
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
                .foregroundColor(viewModel.canGenerate && !storiesStore.isGenerating ? .white : Color.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppTheme.primaryPurple)
                        .opacity(viewModel.canGenerate && !storiesStore.isGenerating ? 1.0 : 0.6)
                )
                .shadow(
                    color: viewModel.canGenerate && !storiesStore.isGenerating ? AppTheme.primaryPurple.opacity(0.4) : .clear,
                    radius: viewModel.canGenerate ? 12 : 0,
                    x: 0,
                    y: 4
                )
                .opacity(viewModel.canGenerate && !storiesStore.isGenerating ? 1.0 : 0.5)
            }
            .disabled(storiesStore.isGenerating)
            .buttonStyle(PlainButtonStyle())
            .animation(.easeInOut(duration: 0.2), value: viewModel.canGenerate)

            if !viewModel.canGenerate {
                Text(LocalizationManager.shared.generateStoryPickThemeOrPlot)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 100)
        .alert(LocalizationManager.shared.generateStoryChooseAdventure, isPresented: $showDisabledGenerateAlert) {
            Button(LocalizationManager.shared.generateStoryGotIt, role: .cancel) { }
        } message: {
            Text(LocalizationManager.shared.generateStoryPickThemeOrPlotAlert)
        }
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
