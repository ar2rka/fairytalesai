import SwiftUI

@MainActor
class GenerateStoryViewModel: ObservableObject {
    @Published var selectedChildId: UUID? = nil
    @Published var selectedDuration: Double = 3
    @Published var selectedTheme: StoryTheme? = nil
    @Published var plot: String = ""
    @Published var showingStoryResult = false
    @Published var showingAddChild = false
    @Published var generatedStory: Story? = nil
    
    func validateDuration(newValue: Double) {
        // Limit duration to 5 minutes max
        if newValue > 5 {
            selectedDuration = 5
        } else if newValue < 3 {
            selectedDuration = 3
        } else {
            selectedDuration = newValue
        }
    }
    
    /// Enable Generate when: child selected AND (theme selected OR plot ≥ 10 chars).
    var canGenerate: Bool {
        guard selectedChildId != nil else { return false }
        let hasTheme = selectedTheme != nil
        let plotTrimmed = plot.trimmingCharacters(in: .whitespaces)
        let hasPlot = plotTrimmed.count >= 10
        return hasTheme || hasPlot
    }

    /// Theme to send to API: selected theme, or "Animals" when only plot is filled.
    var effectiveTheme: StoryTheme? {
        if let t = selectedTheme { return t }
        let plotTrimmed = plot.trimmingCharacters(in: .whitespaces)
        if plotTrimmed.count >= 10 {
            return StoryTheme.allThemes.first { $0.name == "Animals" }
        }
        return nil
    }

    func generateStory(
        userSettings: UserSettings,
        storiesStore: StoriesStore,
        childrenStore: ChildrenStore
    ) {
        guard let theme = effectiveTheme else { return }
        
        let finalDuration = Int(selectedDuration)
        
        // All users can generate stories (including anonymous)
        // Duration is limited to 3-5 minutes for all users
        if !userSettings.isPremium {
            userSettings.useFreeGeneration()
        }
        
        Task {
            await storiesStore.generateStory(
                childId: selectedChildId,
                length: finalDuration,
                theme: theme.name,
                plot: plot.isEmpty ? nil : plot,
                children: childrenStore.children,
                language: userSettings.languageCode
            )
            // Show result only when generation succeeded (no error); otherwise stay on generation page
            guard storiesStore.errorMessage == nil else { return }
            if let storyId = storiesStore.lastGeneratedStoryId,
               let latestStory = storiesStore.stories.first(where: { $0.id == storyId }) {
                self.generatedStory = latestStory
                self.showingStoryResult = true
            } else if let latestStory = storiesStore.stories.first {
                self.generatedStory = latestStory
                self.showingStoryResult = true
            }
        }
    }
}
