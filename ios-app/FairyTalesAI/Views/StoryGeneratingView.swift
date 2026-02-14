import SwiftUI

@MainActor
final class StoryGenerationRunner: ObservableObject {
    init(
        params: StoryGeneratingParams,
        storiesStore: StoriesStore,
        userSettings: UserSettings
    ) {
        print("🏗️ StoryGenerationRunner: init")
        print("   - childId: \(params.childId?.uuidString ?? "nil")")
        print("   - duration: \(params.duration)")
        print("   - theme: \(params.theme)")
        print("   - plot: \(params.plot ?? "nil")")
        print("   - language: \(params.language)")
        print("   - parentId: \(params.parentId?.uuidString ?? "nil")")

        if !userSettings.isPremium {
            userSettings.useFreeGeneration()
        }
        storiesStore.errorMessage = nil

        Task {
            print("📞 StoryGenerationRunner: calling storiesStore.generateStory(theme: \(params.theme), plot: \(params.plot ?? "nil"))")
            await storiesStore.generateStory(
                childId: params.childId,
                length: params.duration,
                theme: params.theme,
                plot: params.plot,
                children: params.children,
                language: params.language,
                parentId: params.parentId
            )
            print("✅ StoryGenerationRunner: storiesStore.generateStory() finished")
        }
    }
}

struct StoryGeneratingView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    let params: StoryGeneratingParams
    let storiesStore: StoriesStore
    let navigationCoordinator: NavigationCoordinator
    var onComplete: (() -> Void)? = nil

    @StateObject private var runner: StoryGenerationRunner
    @State private var hasCompleted = false

    init(
        params: StoryGeneratingParams,
        storiesStore: StoriesStore,
        userSettings: UserSettings,
        navigationCoordinator: NavigationCoordinator,
        onComplete: (() -> Void)? = nil
    ) {
        self.params = params
        self.storiesStore = storiesStore
        self.navigationCoordinator = navigationCoordinator
        self.onComplete = onComplete
        _runner = StateObject(
            wrappedValue: StoryGenerationRunner(
                params: params,
                storiesStore: storiesStore,
                userSettings: userSettings
            )
        )
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Magic generating icon and text
                VStack(spacing: 24) {
                    MagicGeneratingIcon()
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                    
                    MagicGeneratingRow()
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 40)
                
                // Generating button background animation
                VStack(spacing: 16) {
                    GenerateButtonBackground(
                        isGenerating: Binding(
                            get: { storiesStore.isGenerating },
                            set: { _ in }
                        ),
                        isEnabled: true
                    )
                    .frame(height: 60)
                    .overlay(
                        MagicGeneratingRow()
                            .foregroundColor(.white)
                    )
                    .shadow(
                        color: AppTheme.primaryPurple.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                    .padding(.horizontal, 40)
                    
                    // Error message if any
                    if let errorMessage = storiesStore.errorMessage {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 20))
                                
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(AppTheme.cardBackground(for: colorScheme))
                            .cornerRadius(12)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text(LocalizationManager.shared.generateStoryGotIt)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.primaryPurple)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            _ = runner
            print("📱 StoryGeneratingView: onAppear (runner active)")
        }
        .onChange(of: storiesStore.isGenerating) { _, isGenerating in
            if !isGenerating && !hasCompleted {
                handleGenerationComplete()
            }
        }
        .onChange(of: storiesStore.errorMessage) { _, errorMessage in
            if errorMessage != nil {
                // Error occurred, user can close the view
            }
        }
    }

    private func handleGenerationComplete() {
        print("🎯 StoryGeneratingView: Handling generation complete")
        
        // Only proceed if there's no error and we have a generated story
        guard storiesStore.errorMessage == nil else {
            print("❌ StoryGeneratingView: Error occurred: \(storiesStore.errorMessage ?? "unknown")")
            return
        }
        
        if let storyId = storiesStore.lastGeneratedStoryId {
            print("✅ StoryGeneratingView: Story generated with ID: \(storyId)")
            hasCompleted = true
            // Small delay to show completion state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("📚 StoryGeneratingView: Navigating to library with story: \(storyId)")
                navigationCoordinator.switchToLibraryAndOpenStory(storyId)
                // Close this view and parent view
                dismiss()
                onComplete?()
            }
        } else if let latestStory = storiesStore.stories.first {
            print("✅ StoryGeneratingView: Using latest story: \(latestStory.id)")
            hasCompleted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("📚 StoryGeneratingView: Navigating to library with story: \(latestStory.id)")
                navigationCoordinator.switchToLibraryAndOpenStory(latestStory.id)
                // Close this view and parent view
                dismiss()
                onComplete?()
            }
        } else {
            print("⚠️ StoryGeneratingView: No story found after generation")
        }
    }
}
