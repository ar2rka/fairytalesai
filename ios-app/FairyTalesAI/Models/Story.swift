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

    /// Exactly 3 themes for Create Story: Tonight's Pick, age-based, then Space (🚀) — deduped.
    static func visibleThemes(for child: Child?) -> [StoryTheme] {
        let pick = tonightsPick
        var ageBased = ageBasedTheme(for: child)
        let space = allThemes.first { $0.name == "Space" } ?? allThemes[0]
        if ageBased.name == pick.name {
            ageBased = space
        }
        var third = space
        if third.name == pick.name || third.name == ageBased.name {
            third = allThemes.first { $0.name == "Pirates" } ?? allThemes[0]
        }
        return [pick, ageBased, third]
    }
}


