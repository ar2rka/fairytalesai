import Foundation
import SwiftUI
import Combine

@MainActor
class StoriesStore: ObservableObject {
    @Published var stories: [Story] = []
    @Published var isGenerating: Bool = false
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreStories: Bool = true
    @Published var lastGeneratedStoryId: UUID? = nil  // ID последней сгенерированной истории
    
    private let storageKey = "saved_stories"
    private let storiesService = StoriesService.shared
    private let authService = AuthService.shared
    private let pageSize = 10
    private var currentOffset = 0
    private var isLoadingPage = false
    private var authCancellable: AnyCancellable?
    
    init() {
        // Show cached stories immediately so Home "Continue" button can appear without waiting for network
        loadStories()
        // Fetch stories when user becomes available (app launch or sign-in)
        authCancellable = authService.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                Task { @MainActor in
                    if let userId = user?.id {
                        await self.loadStoriesFromSupabase(userId: userId)
                    } else {
                        self.stories = []
                        self.saveStories()
                    }
                }
            }
    }
    
    private func getAccessToken() async throws -> String {
        try await authService.getAccessToken()
    }
    
    func loadStoriesFromSupabase(userId: UUID) async {

        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMoreStories = true
        
        defer { isLoading = false }
        
        do {
            let fetchedStories = try await storiesService.fetchStories(userId: userId, limit: pageSize, offset: 0)
            stories = Self.deduplicatedPreservingOrder(from: fetchedStories)
            currentOffset = stories.count
            hasMoreStories = fetchedStories.count >= pageSize
            saveStories()
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
                let existingIds = Set(stories.map(\.id))
                let newStories = fetchedStories.filter { !existingIds.contains($0.id) }
                stories.append(contentsOf: newStories)
                currentOffset += fetchedStories.count
                hasMoreStories = fetchedStories.count >= pageSize
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка загрузки дополнительных историй: \(error.localizedDescription)")
        }
    }
    
    func generateStory(
        childId: UUID?,
        length: Int,
        theme: String,
        plot: String?,
        children: [Child] = [],
        language: String = "en",
        parentId: UUID? = nil
    ) async {
        print("📍 StoriesStore.generateStory: ENTRY")
        print("   - childId: \(childId?.uuidString ?? "nil")")
        print("   - length: \(length)")
        print("   - theme: \(theme)")
        print("   - plot: \(plot ?? "nil")")
        print("   - language: \(language)")
        print("   - parentId: \(parentId?.uuidString ?? "nil")")
        
        guard let childId = childId else {
            print("📍 StoriesStore.generateStory: EXIT early - childId is nil")
            errorMessage = "Please select a child"
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        defer {
            isGenerating = false
            print("📍 StoriesStore.generateStory: EXIT (defer)")
        }
        
        do {
            // Получаем токен для авторизации
            print("🔑 StoriesStore.generateStory: Получаем access token...")
            let accessToken = try await getAccessToken()
            print("✅ StoriesStore.generateStory: Access token получен")
            
            // Генерируем историю через API
            print("📖 StoriesStore.generateStory: Вызываем storiesService.generateStory()...")
            print("   - Child ID: \(childId)")
            print("   - Theme: \(theme)")
            print("   - Length: \(length)")
            print("   - Language: \(language)")
            print("   - Parent ID: \(parentId?.uuidString ?? "nil")")
            let story = try await storiesService.generateStory(
                childId: childId,
                storyType: "child",
                storyLength: length,
                language: language,
                moral: plot,
                theme: theme,
                accessToken: accessToken,
                parentId: parentId
            )
            print("✅ История получена от API: \(story.title)")
            
            // Пытаемся загрузить полную историю по ID из базы данных
            let finalStory: Story
            if let _ = authService.currentUser?.id,
               let fullStory = try? await storiesService.fetchStory(id: story.id) {
                finalStory = fullStory
                print("✅ История успешно сгенерирована: \(fullStory.title) (ID: \(fullStory.id))")
            } else {
                // Если не удалось загрузить из БД, используем то что вернул API
                finalStory = story
                print("✅ История успешно сгенерирована: \(story.title) (ID: \(story.id))")
            }
            
            // Добавляем историю в список (избегаем дубликата если уже есть)
            if !stories.contains(where: { $0.id == finalStory.id }) {
                stories.insert(finalStory, at: 0)
            }
            
            // Сохраняем ID для автоматического открытия в Library
            lastGeneratedStoryId = finalStory.id
            
            // Сохраняем в Supabase если пользователь авторизован
            if let userId = authService.currentUser?.id {
                _ = try? await storiesService.createStory(finalStory, userId: userId)
            }
        } catch {
            // Обрабатываем различные типы ошибок
            print("📍 StoriesStore.generateStory: CATCH - ошибка: \(error)")
            if let storiesError = error as? StoriesServiceError {
                errorMessage = storiesError.errorDescription ?? error.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("❌ StoriesStore.generateStory: Ошибка генерации истории: \(errorMessage ?? "Unknown error")")
        }
    }
    
    func deleteStory(_ story: Story) {
        stories.removeAll { $0.id == story.id }
        saveStories()
    }
    
    /// Мягкое удаление: помечает историю как удалённую в Supabase (status = "archived") и убирает из локального списка.
    func softDeleteStory(_ story: Story) async {
        do {
            try await storiesService.softDeleteStory(id: story.id)
            stories.removeAll { $0.id == story.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка удаления истории: \(error.localizedDescription)")
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
            stories = Self.deduplicatedPreservingOrder(from: decoded)
        }
    }
    
    /// Removes duplicate stories by id, preserving order (keeps first occurrence).
    private static func deduplicatedPreservingOrder(from stories: [Story]) -> [Story] {
        var seen = Set<UUID>()
        return stories.filter { seen.insert($0.id).inserted }
    }
}

