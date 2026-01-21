import Foundation
import SwiftData

@Model
final class DailyFreeStoriesCache {
    var cachedDate: String // YYYY-MM-DD format
    var stories: [CachedStory]
    
    init(cachedDate: String, stories: [CachedStory]) {
        self.cachedDate = cachedDate
        self.stories = stories
    }
}

@Model
final class CachedStory {
    var id: UUID
    var title: String
    var content: String
    var theme: String
    var duration: Int
    var plot: String?
    var language: String?
    
    init(id: UUID, title: String, content: String, theme: String, duration: Int, plot: String?, language: String?) {
        self.id = id
        self.title = title
        self.content = content
        self.theme = theme
        self.duration = duration
        self.plot = plot
        self.language = language
    }
    
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
            rating: nil
        )
    }
    
    static func fromStory(_ story: Story) -> CachedStory {
        return CachedStory(
            id: story.id,
            title: story.title,
            content: story.content,
            theme: story.theme,
            duration: story.duration,
            plot: story.plot,
            language: story.language
        )
    }
}
