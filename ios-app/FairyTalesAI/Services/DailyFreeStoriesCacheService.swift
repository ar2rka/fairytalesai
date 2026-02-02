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
            if let cached = cached, let stories = cached.getStories() {
                // Возвращаем истории только если их количество > 0
                // Если в кеше 0 историй, возвращаем nil, чтобы загрузить из Supabase
                if stories.isEmpty {
                    print("⚠️ В кеше для даты \(currentDateString) нет историй (0 записей), требуется загрузка из Supabase")
                    return nil
                }
                print("📦 Найдены истории в кеше для даты: \(currentDateString), количество: \(stories.count)")
                return stories
            }
        } catch {
            print("❌ Ошибка чтения кеша: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Сохраняет истории в кеш
    func saveStoriesToCache(_ stories: [Story], modelContext: ModelContext) {
        let currentDateString = getCurrentDateString()
        
        // Удаляем все старые кеши
        clearAllCache(modelContext: modelContext)
        
        // Создаем новый кеш с помощью статического метода
        guard let cache = DailyFreeStoriesCache.create(cachedDate: currentDateString, stories: stories) else {
            print("❌ Не удалось создать кеш для даты: \(currentDateString)")
            return
        }
        
        modelContext.insert(cache)
        
        do {
            try modelContext.save()
            print("💾 Сохранено \(stories.count) историй в кеш для даты: \(currentDateString)")
        } catch {
            print("❌ Ошибка сохранения кеша: \(error.localizedDescription)")
        }
    }
    
    /// Очищает все кешированные истории
    private func clearAllCache(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<DailyFreeStoriesCache>()
        
        do {
            let allCaches = try modelContext.fetch(descriptor)
            for cache in allCaches {
                modelContext.delete(cache)
            }
            
            try modelContext.save()
            if !allCaches.isEmpty {
                print("🗑️ Удалено \(allCaches.count) старых кешей")
            }
        } catch {
            print("❌ Ошибка очистки кеша: \(error.localizedDescription)")
        }
    }
}
