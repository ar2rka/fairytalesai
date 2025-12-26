import Foundation

struct Child: Identifiable, Codable {
    var id: UUID
    var name: String
    var ageCategory: AgeCategory
    var interests: [String]
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, ageCategory: AgeCategory, interests: [String], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.ageCategory = ageCategory
        self.interests = interests
        self.createdAt = createdAt
    }
}

enum AgeCategory: String, Codable, CaseIterable {
    case toddler = "Toddler"
    case preschool = "Preschool"
    case schoolAge = "School Age"
    
    var displayName: String {
        switch self {
        case .toddler:
            return "Toddler (2-3 years)"
        case .preschool:
            return "Preschool (3-5 years)"
        case .schoolAge:
            return "School Age (5-8 years)"
        }
    }
    
    var shortName: String {
        return self.rawValue
    }
}

struct Interest: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let emoji: String
    
    static let allInterests: [Interest] = [
        Interest(name: "Space", emoji: "🚀"),
        Interest(name: "Dinosaurs", emoji: "🦕"),
        Interest(name: "Magic", emoji: "✨"),
        Interest(name: "Animals", emoji: "🦁"),
        Interest(name: "Robots", emoji: "🤖"),
        Interest(name: "Sports", emoji: "⚽"),
        Interest(name: "Princesses", emoji: "👑"),
        Interest(name: "Adventure", emoji: "🗡️"),
        Interest(name: "Nature", emoji: "🌳"),
        Interest(name: "Music", emoji: "🎵"),
        Interest(name: "Art", emoji: "🎨"),
        Interest(name: "Science", emoji: "🔬")
    ]
}


