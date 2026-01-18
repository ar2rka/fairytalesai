import SwiftUI

@MainActor
class GenerateStoryViewModel: ObservableObject {
    @Published var selectedChildId: UUID? = nil
    @Published var selectedDuration: Double = 3
    @Published var selectedTheme: StoryTheme? = nil
    @Published var plot: String = ""
    @Published var showingStoryResult = false
    @Published var showingPaywall = false
    @Published var showingAddChild = false
    @Published var generatedStory: Story? = nil
    
    func validateDuration(newValue: Double, isPremium: Bool) {
         if !isPremium && newValue > 5 {
             // Show paywall immediately
             showingPaywall = true
             // Keep value at 5
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
            
            if let latestStory = storiesStore.stories.first {
                self.generatedStory = latestStory
                self.showingStoryResult = true
            }
        }
    }
}
