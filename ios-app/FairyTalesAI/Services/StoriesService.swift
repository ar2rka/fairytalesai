import Foundation
import Supabase

@MainActor
class StoriesService: ObservableObject {
    static let shared = StoriesService()
    
    private var supabase: SupabaseClient?
    
    init() {
        setupSupabase()
    }
    
    private func setupSupabase() {
        guard SupabaseConfig.isConfigured else {
            print("⚠️ Supabase не настроен. Заполните SupabaseConfig.swift")
            return
        }
        
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            print("⚠️ Неверный Supabase URL")
            return
        }
        
        supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseKey,
            options: SupabaseClientOptions(
                db: .init(
                  schema: "tales"
                )
              )
        )
    }
    
    func fetchStories(userId: UUID) async throws -> [Story] {
        guard let supabase = supabase else {
            throw StoriesError.supabaseNotConfigured
        }
        
        let response: [SupabaseStory] = try await supabase
            .from("stories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.map { $0.toStory() }
    }
    
    func fetchStories(userId: UUID, limit: Int, offset: Int) async throws -> [Story] {
        guard let supabase = supabase else {
            throw StoriesError.supabaseNotConfigured
        }
        
        let response: [SupabaseStory] = try await supabase
            .from("stories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return response.map { $0.toStory() }
    }
    
    func fetchStory(id: UUID) async throws -> Story? {
        guard let supabase = supabase else {
            throw StoriesError.supabaseNotConfigured
        }
        
        let response: SupabaseStory? = try await supabase
            .from("stories")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return response?.toStory()
    }
}

// MARK: - Supabase Story Model
private struct SupabaseStory: Codable {
    let id: UUID
    let title: String
    let content: String
    let childId: UUID?
    let createdAt: String
    let language: String?
    let rating: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case childId = "child_id"
        case createdAt = "created_at"
        case language
        case rating
    }
    
    func toStory() -> Story {
        // Parse date - Supabase returns ISO8601 format
        var createdAtDate = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let parsedDate = dateFormatter.date(from: createdAt) {
            createdAtDate = parsedDate
        } else {
            // Fallback: try without fractional seconds
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let parsedDate = dateFormatter.date(from: createdAt) {
                createdAtDate = parsedDate
            }
        }
        
        return Story(
            id: id,
            title: title,
            content: content,
            childId: childId,
            theme: "Adventure", // Default theme, можно извлечь из других полей если нужно
            duration: estimateDuration(from: content),
            plot: nil,
            createdAt: createdAtDate,
            favoriteStatus: false,
            language: language ?? "en",
            rating: rating
        )
    }
    
    private func estimateDuration(from content: String) -> Int {
        // Примерная оценка: ~200 слов в минуту чтения
        let wordCount = content.split(separator: " ").count
        return max(1, wordCount / 200)
    }
}

enum StoriesError: LocalizedError {
    case supabaseNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "Supabase не настроен. Пожалуйста, заполните конфигурацию."
        }
    }
}

