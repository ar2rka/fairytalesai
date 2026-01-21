import Foundation
import SwiftData

@MainActor
class DailyFreeStoriesCacheService {
    static let shared = DailyFreeStoriesCacheService()
    
    private init() {}
    
    /// Получает текущую дату в формате YYYY-MM-DD
    private func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.string(from: Date())
    }
    
    /// Получает истории из кеша, если они есть для текущей даты
    func getCachedStories(modelContext: ModelContext) -> [Story]? {
        let currentDateString = getCurrentDateString()
        
        let descriptor = FetchDescriptor<DailyFreeStoriesCache>(
            predicate: #Predicate { $0.cachedDate == currentDateString }
        )
        
        do {
            let cached = try modelContext.fetch(descriptor).first
            if let cached = cached {
                print("📦 Найдены истории в кеше для даты: \(currentDateString)")
                return cached.stories.map { $0.toStory() }
            }
        } catch {
            print("❌ Ошибка чтения кеша: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Сохраняет истории в кеш
    func saveStoriesToCache(_ stories: [Story], modelContext: ModelContext) {
        let currentDateString = getCurrentDateString()
        
        // Удаляем старые кешированные истории
        clearOldCache(modelContext: modelContext)
        
        // Создаем новые кешированные истории и вставляем их в контекст
        let cachedStories = stories.map { story -> CachedStory in
            let cachedStory = CachedStory.fromStory(story)
            modelContext.insert(cachedStory)
            return cachedStory
        }
        
        let cache = DailyFreeStoriesCache(cachedDate: currentDateString, stories: cachedStories)
        modelContext.insert(cache)
        
        do {
            try modelContext.save()
            print("💾 Сохранено \(stories.count) историй в кеш для даты: \(currentDateString)")
        } catch {
            print("❌ Ошибка сохранения кеша: \(error.localizedDescription)")
        }
    }
    
    /// Очищает старые кешированные истории (для других дат)
    private func clearOldCache(modelContext: ModelContext) {
        let currentDateString = getCurrentDateString()
        
        let descriptor = FetchDescriptor<DailyFreeStoriesCache>(
            predicate: #Predicate { $0.cachedDate != currentDateString }
        )
        
        do {
            let oldCaches = try modelContext.fetch(descriptor)
            for cache in oldCaches {
                modelContext.delete(cache)
            }
            try modelContext.save()
            if !oldCaches.isEmpty {
                print("🗑️ Удалено \(oldCaches.count) старых кешей")
            }
        } catch {
            print("❌ Ошибка очистки старого кеша: \(error.localizedDescription)")
        }
    }
}
