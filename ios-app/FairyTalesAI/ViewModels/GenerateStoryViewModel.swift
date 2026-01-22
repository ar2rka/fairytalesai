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
