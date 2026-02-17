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
                GenerateStoryEmptyStateView(showingAddChild: $viewModel.showingAddChild, onClose: { dismiss() })
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        childrenSelectionSection
                        
                        DurationSectionView(selectedDuration: $viewModel.selectedDuration)
                        
                        ThemeSelectionSection(
                            selectedTheme: $viewModel.selectedTheme,
                            showAllThemes: $showAllThemes,
                            selectedChild: selectedChildForThemes
                        )
                        
                        PlotSectionView(plot: $viewModel.plot)
                        
                        // Отображение ошибок
                        if let errorMessage = storiesStore.errorMessage {
                            errorAlertView(message: errorMessage)
                        }
                        
                        generateButton
                    }
                }
                .contentMargins(.top, 0, for: .scrollContent)
            }
            
            // Liquid Glass Close Button - top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        HapticFeedback.impact()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            .frame(width: 36, height: 36)
                            .background(
                                ZStack {
                                    // Glass effect with blur
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(.ultraThinMaterial)
                                    
                                    // Subtle border
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    AppTheme.textPrimary(for: colorScheme).opacity(0.3),
                                                    AppTheme.textPrimary(for: colorScheme).opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 3)
                    }
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            .padding(.top, 8)
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
    
    // MARK: - Children Selection
    
    private var selectedChildForThemes: Child? {
        guard let id = viewModel.selectedChildId else { return nil }
        return childrenStore.children.first { $0.id == id }
    }
    
    private var childrenSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.generateStoryWhoIsListening)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            if childrenStore.isLoading && childrenStore.children.isEmpty {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryPurple))
                    Text(LocalizationManager.shared.generateStoryLoadingChildren)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if childrenStore.children.isEmpty {
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
            } else {
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
        }
        .padding(.horizontal)
    }
    
    // MARK: - Error Alert
    
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

    // MARK: - Generate Button
    
    private var generateButton: some View {
        VStack(spacing: 8) {
            Button(action: {
                if !viewModel.canGenerate {
                    showDisabledGenerateAlert = true
                    return
                }
                
                guard let theme = viewModel.effectiveTheme else { return }
                
                let params = StoryGeneratingParams(
                    childId: viewModel.selectedChildId,
                    duration: Int(viewModel.selectedDuration),
                    theme: theme.name,
                    plot: viewModel.plot.isEmpty ? nil : viewModel.plot,
                    parentId: nil,
                    children: childrenStore.children,
                    language: userSettings.languageCode
                )
                
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
