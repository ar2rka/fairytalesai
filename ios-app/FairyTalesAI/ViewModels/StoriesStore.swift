import Foundation
import SwiftUI

@MainActor
class StoriesStore: ObservableObject {
    @Published var stories: [Story] = []
    @Published var isGenerating: Bool = false
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreStories: Bool = true
    
    private let storageKey = "saved_stories"
    private let storiesService = StoriesService.shared
    private let guestDataManager = GuestDataManager.shared
    private let authService = AuthService.shared
    private let pageSize = 10
    private var currentOffset = 0
    private var isLoadingPage = false
    
    init() {
        // Load guest stories if in guest mode
        if authService.isGuest {
            stories = guestDataManager.loadGuestStories()
        }
    }
    
    func loadStoriesFromSupabase(userId: UUID) async {
        // If in guest mode, stories are already loaded from local storage in init
        if authService.isGuest {
            return
        }
        
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMoreStories = true
        
        defer { isLoading = false }
        
        do {
            let fetchedStories = try await storiesService.fetchStories(userId: userId, limit: pageSize, offset: 0)
            stories = fetchedStories
            currentOffset = fetchedStories.count
            hasMoreStories = fetchedStories.count >= pageSize
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка загрузки историй: \(error.localizedDescription)")
        }
    }
    
    func loadMoreStories(userId: UUID) async {
        guard !isLoadingPage && hasMoreStories else { return }
        
        isLoadingPage = true
        isLoadingMore = true
        errorMessage = nil
        
        defer {
            isLoadingPage = false
            isLoadingMore = false
        }
        
        do {
            let fetchedStories = try await storiesService.fetchStories(userId: userId, limit: pageSize, offset: currentOffset)
            
            if fetchedStories.isEmpty {
                hasMoreStories = false
            } else {
                stories.append(contentsOf: fetchedStories)
                currentOffset += fetchedStories.count
                hasMoreStories = fetchedStories.count >= pageSize
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка загрузки дополнительных историй: \(error.localizedDescription)")
        }
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
            duration: length,
            plot: plot
        )
        
        await MainActor.run {
            stories.insert(story, at: 0)
            
            // Save to appropriate location based on auth state
            if authService.isGuest {
                guestDataManager.saveGuestStories(stories)
            } else {
                saveStories()
            }
            
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
        
        // Save to appropriate location based on auth state
        if authService.isGuest {
            guestDataManager.saveGuestStories(stories)
        } else {
            saveStories()
        }
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

