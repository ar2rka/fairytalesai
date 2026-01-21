import Foundation
import SwiftUI
import Supabase

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
    private let guestDataManager = GuestDataManager.shared
    private let authService = AuthService.shared
    private let pageSize = 10
    private var currentOffset = 0
    private var isLoadingPage = false
    private var supabase: SupabaseClient?
    
    init() {
        setupSupabase()
        // Load guest stories if in guest mode
        if authService.isGuest {
            stories = guestDataManager.loadGuestStories()
        }
    }
    
    private func setupSupabase() {
        guard SupabaseConfig.isConfigured else {
            print("⚠️ Supabase не настроен. Заполните SupabaseConfig.swift")
            return
        }
        
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            print("⚠️ Неверный Supabase URL")
            return
        }
        
        supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseKey,
            options: SupabaseClientOptions(
                db: .init(
                  schema: "tales"
                ),
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
              )
        )
    }
    
    private func getAccessToken() async throws -> String {
        guard let supabase = supabase else {
            throw StoriesServiceError.supabaseNotConfigured
        }
        
        let session = try await supabase.auth.session
        return session.accessToken
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
    
    func generateStory(
        childId: UUID?,
        length: Int,
        theme: String,
        plot: String?,
        children: [Child] = [],
        language: String = "en"
    ) async {
        guard let childId = childId else {
            errorMessage = "Please select a child"
            return
        }
        
        // Требуем авторизацию для генерации историй
        guard !authService.isGuest else {
            errorMessage = "Please sign in to generate stories"
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        do {
            // Получаем токен для авторизации
            print("🔑 Получаем access token...")
            let accessToken = try await getAccessToken()
            print("✅ Access token получен")
            
            // Генерируем историю через API
            print("📖 Начинаем генерацию истории через API...")
            print("   - Child ID: \(childId)")
            print("   - Theme: \(theme)")
            print("   - Length: \(length)")
            print("   - Language: \(language)")
            let story = try await storiesService.generateStory(
                childId: childId,
                storyType: theme,
                storyLength: length,
                language: language,
                moral: plot,
                accessToken: accessToken
            )
            print("✅ История получена от API: \(story.title)")
            
            // Пытаемся загрузить полную историю по ID из базы данных
            let finalStory: Story
            if let userId = authService.currentUser?.id,
               let fullStory = try? await storiesService.fetchStory(id: story.id) {
                finalStory = fullStory
                print("✅ История успешно сгенерирована: \(fullStory.title) (ID: \(fullStory.id))")
            } else {
                // Если не удалось загрузить из БД, используем то что вернул API
                finalStory = story
                print("✅ История успешно сгенерирована: \(story.title) (ID: \(story.id))")
            }
            
            // Добавляем историю в список
            stories.insert(finalStory, at: 0)
            
            // Сохраняем ID для автоматического открытия в Library
            lastGeneratedStoryId = finalStory.id
            
            // Сохраняем в Supabase если пользователь авторизован
            if let userId = authService.currentUser?.id {
                _ = try? await storiesService.createStory(finalStory, userId: userId)
            }
        } catch {
            // Обрабатываем различные типы ошибок
            if let storiesError = error as? StoriesServiceError {
                errorMessage = storiesError.errorDescription ?? error.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("❌ Ошибка генерации истории: \(errorMessage ?? "Unknown error")")
        }
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

