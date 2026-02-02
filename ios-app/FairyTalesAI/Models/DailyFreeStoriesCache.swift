import Foundation
import SwiftData

@Model
final class DailyFreeStoriesCache {
    var cachedDate: String // YYYY-MM-DD format
    @Attribute(.externalStorage) var storiesData: Data // Хранение историй как Data
    
    init(cachedDate: String, storiesData: Data) {
        self.cachedDate = cachedDate
        self.storiesData = storiesData
    }
    
    // Вспомогательные методы для работы со Story
    func getStories() -> [Story]? {
        let decoder = JSONDecoder()
        return try? decoder.decode([CachedStoryData].self, from: storiesData).map { $0.toStory() }
    }
    
    static func create(cachedDate: String, stories: [Story]) -> DailyFreeStoriesCache? {
        let encoder = JSONEncoder()
        let cachedData = stories.map { CachedStoryData.fromStory($0) }
        guard let data = try? encoder.encode(cachedData) else { return nil }
        return DailyFreeStoriesCache(cachedDate: cachedDate, storiesData: data)
    }
}

// Простая структура для кодирования/декодирования
struct CachedStoryData: Codable {
    var id: UUID
    var title: String
    var content: String
    var theme: String
    var duration: Int
    var plot: String?
    var language: String?
    var ageCategory: String
    
    func toStory() -> Story {
        return Story(
            id: id,
            title: title,
            content: content,
            childId: nil,
            theme: theme,
            duration: duration,
            plot: plot,
            createdAt: Date(),
            favoriteStatus: false,
            language: language ?? "en",
            rating: nil,
            ageCategory: ageCategory
        )
    }
    
    static func fromStory(_ story: Story) -> CachedStoryData {
        return CachedStoryData(
            id: story.id,
            title: story.title,
            content: story.content,
            theme: story.theme,
            duration: story.duration,
            plot: story.plot,
            language: story.language,
            ageCategory: story.ageCategory
        )
    }
}
