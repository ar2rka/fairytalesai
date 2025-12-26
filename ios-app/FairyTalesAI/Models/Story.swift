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
    
    init(id: UUID = UUID(), title: String, content: String, childId: UUID? = nil, theme: String, duration: Int, plot: String? = nil, createdAt: Date = Date(), favoriteStatus: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.childId = childId
        self.theme = theme
        self.duration = duration
        self.plot = plot
        self.createdAt = createdAt
        self.favoriteStatus = favoriteStatus
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
        StoryTheme(name: "Adventure", description: "Knights & Castles", emoji: "🏰"),
        StoryTheme(name: "Animals", description: "Forest Friends", emoji: "🦁"),
        StoryTheme(name: "Mystery", description: "Clues & Secrets", emoji: "🔍"),
        StoryTheme(name: "Princess", description: "Royal Adventures", emoji: "👑"),
        StoryTheme(name: "Learning", description: "Educational Fun", emoji: "💡")
    ]
}


