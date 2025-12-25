import Foundation

struct Story: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String
    var childId: UUID?
    var theme: String
    var length: Int // in minutes
    var plot: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, content: String, childId: UUID? = nil, theme: String, length: Int, plot: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.childId = childId
        self.theme = theme
        self.length = length
        self.plot = plot
        self.createdAt = createdAt
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

