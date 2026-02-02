import Foundation

enum FlagEmoji {
    /// Returns a flag emoji for the given language code (e.g. "en" -> "🇺🇸").
    static func flag(for languageCode: String) -> String? {
        switch languageCode.lowercased() {
        case "en": return "🇺🇸"
        case "ru": return "🇷🇺"
        default: return nil
        }
    }
}
