import SwiftUI

struct GenerateStoryView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var storiesStore: StoriesStore
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var createStoryPresentation: CreateStoryPresentation
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel = GenerateStoryViewModel()
    @State private var showDisabledGenerateAlert = false
    @State private var showAllThemes = false
    
    /// When opening from "Tonight's Pick" on Home, this theme is preselected.
    var preselectedTheme: StoryTheme? = nil
    /// When opening from "Continue Last Night's Adventure", summary of the latest story for the new plot.
    var preselectedPlot: String? = nil
    
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
                if let homeSelectedId = childrenStore.selectedChildId,
                   childrenStore.children.contains(where: { $0.id == homeSelectedId }) {
                    viewModel.selectedChildId = homeSelectedId
                } else if childrenStore.children.count == 1 {
                    viewModel.selectedChildId = childrenStore.children.first?.id
                }
                if let theme = preselectedTheme {
                    viewModel.selectedTheme = theme
                }
                if let plot = preselectedPlot, !plot.isEmpty {
                    viewModel.plot = plot
                }
            }
            .onChange(of: childrenStore.children.count) { _, newCount in
                if let homeSelectedId = childrenStore.selectedChildId,
                   childrenStore.children.contains(where: { $0.id == homeSelectedId }) {
                    viewModel.selectedChildId = homeSelectedId
                } else if newCount == 1 {
                    viewModel.selectedChildId = childrenStore.children.first?.id
                }
            }
            .onChange(of: viewModel.selectedChildId) { _, newId in
                if let id = newId {
                    childrenStore.selectedChildId = id
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

    private var generateButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                if !viewModel.canGenerate {
                    showDisabledGenerateAlert = true
                    return
                }
                
                guard let theme = viewModel.effectiveTheme else { return }
                
                // Prepare parameters for StoryGeneratingView
                let params = StoryGeneratingParams(
                    childId: viewModel.selectedChildId,
                    duration: Int(viewModel.selectedDuration),
                    theme: theme.name,
                    plot: viewModel.plot.isEmpty ? nil : viewModel.plot,
                    parentId: nil,
                    children: childrenStore.children,
                    language: userSettings.languageCode
                )
                
                print("🎯 GenerateStoryView: Creating StoryGeneratingParams")
                print("   - Child ID: \(params.childId?.uuidString ?? "nil")")
                print("   - Duration: \(params.duration)")
                print("   - Theme: \(params.theme)")
                print("   - Plot: \(params.plot ?? "nil")")
                print("   - Language: \(params.language)")
                
                // Avoid presenting a second fullScreenCover while this one is still visible.
                // First dismiss Create Story screen, then present Generating screen.
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    createStoryPresentation.presentGenerating(params: params)
                }
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text(LocalizationManager.shared.generateStoryGenerateStory)
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    GenerateButtonBackground(
                        isGenerating: Binding(
                            get: { false },
                            set: { _ in }
                        ),
                        isEnabled: viewModel.canGenerate
                    )
                )
                .shadow(
                    color: viewModel.canGenerate ? AppTheme.primaryPurple.opacity(0.4) : .clear,
                    radius: viewModel.canGenerate ? 12 : 0,
                    x: 0,
                    y: 4
                )
                .opacity(viewModel.canGenerate ? 1.0 : 0.5)
            }
            .disabled(!viewModel.canGenerate)
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
}

// MARK: - Magic generating content (shared with HomeView Continue button)

struct MagicGeneratingRow: View {
    /// One phrase per generation: set when row appears, never change during this generation.
    @State private var phrase: String = ""

    private var phrases: [String] {
        LocalizationManager.shared.generateStoryMagicPhrases
    }

    var body: some View {
        HStack {
            MagicGeneratingIcon()
            Text(phrase.isEmpty ? LocalizationManager.shared.generateStoryGenerating : phrase)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .onAppear {
            phrase = phrases.randomElement() ?? LocalizationManager.shared.generateStoryGenerating
        }
    }
}

struct MagicGeneratingIcon: View {
    var body: some View {
        Image(systemName: "wand.and.stars")
            .font(.system(size: 20, weight: .bold))
    }
}

// MARK: - Generate button background: static purple + conditional shimmer while generating (shared with HomeView)
struct GenerateButtonBackground: View {
    @Binding var isGenerating: Bool
    let isEnabled: Bool
    @State private var shimmerStartTime = Date()
    
    private static let violetA = Color(red: 0x66 / 255, green: 0x7e / 255, blue: 0xea / 255) // #667eea
    private static let violetB = Color(red: 0x76 / 255, green: 0x4b / 255, blue: 0xa2 / 255) // #764ba2
    private static let violetC = Color(red: 0xf0 / 255, green: 0x93 / 255, blue: 0xfb / 255) // #f093fb
    private static let auroraCyan = Color(red: 0x48 / 255, green: 0xd9 / 255, blue: 0xff / 255)
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(isEnabled || isGenerating ? 1.0 : 0.6)
                
                if isGenerating {
                    TimelineView(.animation(minimumInterval: 1.0 / 45.0, paused: !isGenerating)) { context in
                        auroraShimmerOverlay(size: proxy.size, now: context.date)
                    }
                    .transition(.opacity)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .onChange(of: isGenerating) { _, newValue in
            if newValue {
                shimmerStartTime = Date()
            }
        }
        .animation(.easeInOut(duration: 0.28), value: isGenerating)
    }
    
    private func auroraShimmerOverlay(size: CGSize, now: Date) -> some View {
        let elapsed = now.timeIntervalSince(shimmerStartTime)
        _ = size
        
        let sweep = CGFloat((elapsed / 2.1).truncatingRemainder(dividingBy: 1.0))
        let sweep2 = CGFloat((elapsed / 3.4).truncatingRemainder(dividingBy: 1.0))
        
        // Full-surface movement: gradient vectors travel beyond bounds,
        // but the fill always covers the whole button.
        let startA = UnitPoint(x: -1.0 + 2.0 * sweep, y: 0.0)
        let endA = UnitPoint(x: 0.6 + 2.0 * sweep, y: 1.0)
        let startB = UnitPoint(x: 1.2 - 2.0 * sweep2, y: 0.2)
        let endB = UnitPoint(x: -0.4 - 2.0 * sweep2, y: 0.9)
        let swirl = Angle.degrees(elapsed * 24.0)
        
        return ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            Self.violetA.opacity(0.42),
                            Self.violetB.opacity(0.28),
                            Self.violetC.opacity(0.46),
                            Self.violetB.opacity(0.32),
                            Self.violetA.opacity(0.42)
                        ],
                        startPoint: startA,
                        endPoint: endA
                    )
                )
            
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Self.auroraCyan.opacity(0.22),
                            Self.violetC.opacity(0.32),
                            Self.violetA.opacity(0.18),
                            Self.auroraCyan.opacity(0.22)
                        ]),
                        center: .center,
                        angle: swirl
                    )
                )
            
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            Self.auroraCyan.opacity(0.0),
                            Self.auroraCyan.opacity(0.28),
                            Self.violetC.opacity(0.0)
                        ],
                        startPoint: startB,
                        endPoint: endB
                    )
                )
        }
        .opacity(0.92)
        .blendMode(.plusLighter)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}

