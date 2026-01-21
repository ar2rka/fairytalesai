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
    
    func validateDuration(newValue: Double, isPremium: Bool) {
         if !isPremium && newValue > 5 {
             // Limit free users to 5 minutes max, no paywall
             selectedDuration = 5
         } else {
             selectedDuration = newValue
         }
    }
    
    var canGenerate: Bool {
        selectedChildId != nil && selectedTheme != nil
    }
    
    func generateStory(
        userSettings: UserSettings,
        storiesStore: StoriesStore,
        childrenStore: ChildrenStore
    ) {
        guard let theme = selectedTheme else { return }
        
        let finalDuration = Int(selectedDuration)
        
        // No paywall - allow generation for all users (including anonymous)
        // Free users are limited to 5 minutes max duration (enforced by validateDuration)
        // Use a free generation if not premium (optional - can be removed if unlimited)
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
            
            // Используем lastGeneratedStoryId для более надежного определения последней истории
            if let storyId = storiesStore.lastGeneratedStoryId,
               let latestStory = storiesStore.stories.first(where: { $0.id == storyId }) {
                self.generatedStory = latestStory
                self.showingStoryResult = true
            } else if let latestStory = storiesStore.stories.first {
                // Fallback на первую историю в списке
                self.generatedStory = latestStory
                self.showingStoryResult = true
            }
        }
    }
}
