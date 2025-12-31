import Foundation

struct Story: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String
    var childId: UUID?
    var theme: String
    var duration: Int // in minutes (renamed from length)
    var plot: String?
    var createdAt: Date
    var favoriteStatus: Bool
    var language: String?
    var rating: Int?
    
    // Supabase field mappings
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case childId = "child_id"
        case theme
        case duration
        case plot
        case createdAt = "created_at"
        case favoriteStatus
        case language
        case rating
    }
    
    init(id: UUID = UUID(), title: String, content: String, childId: UUID? = nil, theme: String, duration: Int, plot: String? = nil, createdAt: Date = Date(), favoriteStatus: Bool = false, language: String? = nil, rating: Int? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.childId = childId
        self.theme = theme
        self.duration = duration
        self.plot = plot
        self.createdAt = createdAt
        self.favoriteStatus = favoriteStatus
        self.language = language
        self.rating = rating
    }
    
    // Legacy support for 'length' property
    var length: Int {
        get { duration }
        set { duration = newValue }
    }
}

struct StoryTheme: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let emoji: String
    
    static let allThemes: [StoryTheme] = [
        StoryTheme(name: "Space", description: "Galaxies & Aliens", emoji: "🚀"),
        StoryTheme(name: "Pirates", description: "Treasure & Adventure", emoji: "🏴‍☠️"),
        StoryTheme(name: "Dinosaurs", description: "Prehistoric Adventures", emoji: "🦖"),
        StoryTheme(name: "Mermaids", description: "Ocean Magic", emoji: "🧜‍♀️"),
        StoryTheme(name: "Animals", description: "Forest Friends", emoji: "🦁"),
        StoryTheme(name: "Mystery", description: "Clues & Secrets", emoji: "🔍"),
        StoryTheme(name: "Magic School", description: "Wizardry & Spells", emoji: "🏰"),
        StoryTheme(name: "Robots", description: "Tech Adventures", emoji: "🤖")
    ]
}


