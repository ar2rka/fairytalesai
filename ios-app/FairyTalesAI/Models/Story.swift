import Foundation
import SwiftUI

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
    var ageCategory: String
    
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
        case ageCategory = "age_category"
    }
    
    init(id: UUID = UUID(), title: String, content: String, childId: UUID? = nil, theme: String, duration: Int, plot: String? = nil, createdAt: Date = Date(), favoriteStatus: Bool = false, language: String? = nil, rating: Int? = nil, ageCategory: String) {
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
        self.ageCategory = ageCategory
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
    
    var localizedName: String {
        LocalizationManager.shared.localizedThemeName(name)
    }
    
    /// Цвет темы, используемый для акцентов в UI.
    var color: Color {
        Self.color(for: name)
    }
    
    /// Градиент фона карточки темы.
    var gradient: [Color] {
        Self.gradient(for: name)
    }
    
    // MARK: - Static helpers (для работы с raw-строками, например story.theme)
    
    static func color(for themeName: String) -> Color {
        switch themeName.lowercased() {
        case "space": return Color(red: 1.0, green: 0.65, blue: 0.0)
        case "pirates": return Color(red: 0.8, green: 0.6, blue: 0.2)
        case "dinosaurs": return Color(red: 0.2, green: 0.8, blue: 0.2)
        case "mermaids": return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "animals": return Color(red: 0.4, green: 0.7, blue: 0.3)
        case "mystery": return Color(red: 0.6, green: 0.3, blue: 0.8)
        case "magic school": return Color(red: 0.8, green: 0.3, blue: 0.8)
        case "robots": return Color(red: 0.5, green: 0.5, blue: 0.5)
        default: return AppTheme.primaryPurple
        }
    }
    
    static func emoji(for themeName: String) -> String {
        if let theme = allThemes.first(where: { $0.name.lowercased() == themeName.lowercased() }) {
            return theme.emoji
        }
        // Дополнительные темы для ежедневных бесплатных историй
        switch themeName.lowercased() {
        case "fairies": return "🧚"
        case "forest", "adventure": return "🌲"
        case "dragon", "dragons": return "🐉"
        default: return "📖"
        }
    }
    
    static func gradient(for themeName: String) -> [Color] {
        switch themeName.lowercased() {
        case "space":
            return [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.1, blue: 0.3)]
        case "pirates":
            return [Color(red: 0.3, green: 0.2, blue: 0.1), Color(red: 0.4, green: 0.3, blue: 0.15)]
        case "animals":
            return [Color(red: 0.2, green: 0.4, blue: 0.2), Color(red: 0.15, green: 0.35, blue: 0.15)]
        case "fairies":
            return [Color(red: 0.4, green: 0.2, blue: 0.4), Color(red: 0.5, green: 0.3, blue: 0.5)]
        case "forest", "adventure":
            return [Color(red: 0.1, green: 0.3, blue: 0.2), Color(red: 0.15, green: 0.4, blue: 0.25)]
        case "dragon", "dragons":
            return [Color(red: 0.4, green: 0.1, blue: 0.1), Color(red: 0.5, green: 0.15, blue: 0.15)]
        case "dinosaurs":
            return [Color(red: 0.15, green: 0.35, blue: 0.15), Color(red: 0.2, green: 0.4, blue: 0.2)]
        case "mermaids":
            return [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.15, green: 0.3, blue: 0.5)]
        case "mystery":
            return [Color(red: 0.25, green: 0.1, blue: 0.35), Color(red: 0.35, green: 0.15, blue: 0.45)]
        case "magic school":
            return [Color(red: 0.3, green: 0.1, blue: 0.3), Color(red: 0.4, green: 0.15, blue: 0.4)]
        case "robots":
            return [Color(red: 0.2, green: 0.2, blue: 0.25), Color(red: 0.3, green: 0.3, blue: 0.35)]
        default:
            return [AppTheme.primaryPurple.opacity(0.6), AppTheme.accentPurple.opacity(0.6)]
        }
    }
    
    var localizedDescription: String {
        let localizer = LocalizationManager.shared
        switch name.lowercased() {
        case "space": return localizer.themeSpaceDesc
        case "pirates": return localizer.themePiratesDesc
        case "dinosaurs": return localizer.themeDinosaursDesc
        case "mermaids": return localizer.themeMermaidsDesc
        case "animals": return localizer.themeAnimalsDesc
        case "mystery": return localizer.themeMysteryDesc
        case "magic school": return localizer.themeMagicSchoolDesc
        case "robots": return localizer.themeRobotsDesc
        default: return description
        }
    }
    
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

    /// Calm themes for evening (6pm–10pm): gentle, bedtime-friendly.
    private static let calmThemeNames = ["Mermaids", "Animals"]
    /// Adventure themes for daytime/afternoon.
    private static let adventureThemeNames = ["Space", "Pirates", "Dinosaurs"]

    /// Returns a theme based on current time: calm in evening (18–22), adventure otherwise.
    static var tonightsPick: StoryTheme {
        let hour = Calendar.current.component(.hour, from: Date())
        let isEvening = (18..<22).contains(hour)
        let names = isEvening ? calmThemeNames : adventureThemeNames
        let name = names[abs(hour) % names.count]
        return allThemes.first { $0.name == name } ?? allThemes[0]
    }

    /// Age-based theme for Create Story (Slot 2). Uses Animals as fallback when child/age unknown.
    private static func ageBasedTheme(for child: Child?) -> StoryTheme {
        guard let child = child else {
            return allThemes.first { $0.name == "Animals" } ?? allThemes[0]
        }
        switch child.ageCategory {
        case .twoThree: return allThemes.first { $0.name == "Animals" } ?? allThemes[0]
        case .threeFive: return allThemes.first { $0.name == "Dinosaurs" } ?? allThemes[0]
        case .fiveSeven, .eightPlus: return allThemes.first { $0.name == "Space" } ?? allThemes[0]
        }
    }

    /// Exactly 2 themes for Create Story: Tonight's Pick and age-based — deduped.
    static func visibleThemes(for child: Child?) -> [StoryTheme] {
        let pick = tonightsPick
        var ageBased = ageBasedTheme(for: child)
        if ageBased.name == pick.name {
            // If age-based matches Tonight's Pick, use Space as the second theme
            ageBased = allThemes.first { $0.name == "Space" } ?? allThemes[0]
        }
        return [pick, ageBased]
    }
}


