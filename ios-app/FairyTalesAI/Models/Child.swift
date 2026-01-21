import Foundation

struct Child: Identifiable, Codable {
    var id: UUID
    var name: String
    var gender: String
    var ageCategory: AgeCategory
    var interests: [String]
    var userId: UUID?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        gender: String,
        ageCategory: AgeCategory,
        interests: [String],
        userId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.ageCategory = ageCategory
        self.interests = interests
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum AgeCategory: String, Codable, CaseIterable {
    case twoThree = "2-3"
    case threeFive = "3-5"
    case fiveSeven = "5-7"
    case eightPlus = "8+"
    
    var displayName: String {
        switch self {
        case .twoThree:
            return "2-3 years"
        case .threeFive:
            return "3-5 years"
        case .fiveSeven:
            return "5-7 years"
        case .eightPlus:
            return "8+ years"
        }
    }
    
    var shortName: String {
        return self.rawValue
    }
}

enum StoryStyle: String, Codable, CaseIterable {
    case hero = "hero"
    case boy = "male"
    case girl = "female"
    
    var displayName: String {
        switch self {
        case .hero:
            return "The Hero"
        case .boy:
            return "Boy"
        case .girl:
            return "Girl"
        }
    }
    
    var icon: String {
        switch self {
        case .hero:
            return "✨"
        case .boy:
            return "👦"
        case .girl:
            return "👧"
        }
    }
    
    // Map to gender string for backward compatibility
    var genderString: String {
        switch self {
        case .hero:
            return "other"
        case .boy:
            return "male"
        case .girl:
            return "female"
        }
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


