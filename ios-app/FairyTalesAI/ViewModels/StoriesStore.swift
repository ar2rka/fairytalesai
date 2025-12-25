import Foundation
import SwiftUI

class StoriesStore: ObservableObject {
    @Published var stories: [Story] = []
    @Published var isGenerating: Bool = false
    private let storageKey = "saved_stories"
    
    init() {
        loadStories()
    }
    
    func generateStory(childId: UUID?, length: Int, theme: String, plot: String?, children: [Child] = []) async {
        isGenerating = true
        
        // Simulate API call - replace with actual API integration
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let child = childId != nil ? 
            children.first(where: { $0.id == childId }) : nil
        
        let story = Story(
            title: "\(child?.name ?? "The") and the \(theme) Adventure",
            content: generateStoryContent(child: child, theme: theme, plot: plot, length: length),
            childId: childId,
            theme: theme,
            length: length,
            plot: plot
        )
        
        await MainActor.run {
            stories.insert(story, at: 0)
            saveStories()
            isGenerating = false
        }
    }
    
    private func generateStoryContent(child: Child?, theme: String, plot: String?, length: Int) -> String {
        let childName = child?.name ?? "the hero"
        let interests = child?.interests.joined(separator: ", ") ?? "adventure"
        
        var content = "Once upon a time, there was a child named \(childName) who loved \(interests).\n\n"
        
        if let plot = plot, !plot.isEmpty {
            content += "\(plot)\n\n"
        }
        
        content += "In a magical world of \(theme), \(childName) embarked on an incredible journey. "
        content += "The adventure lasted \(length) minutes of pure wonder and excitement.\n\n"
        content += "Through courage and kindness, \(childName) discovered that the greatest magic of all was friendship and love.\n\n"
        content += "And so, \(childName) returned home with a heart full of joy and memories that would last forever.\n\nThe End."
        
        return content
    }
    
    func deleteStory(_ story: Story) {
        stories.removeAll { $0.id == story.id }
        saveStories()
    }
    
    private func saveStories() {
        if let encoded = try? JSONEncoder().encode(stories) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadStories() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Story].self, from: data) {
            stories = decoded
        }
    }
}

