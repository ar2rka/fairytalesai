import Foundation
import Supabase
import SwiftData

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
                ),
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
              )
        )
    }
    
    /// Загружает истории пользователя; исключает записи с status = "archived". В таблице stories должна быть колонка status (например default 'active').
    func fetchStories(userId: UUID) async throws -> [Story] {
        guard let supabase = supabase else {
            throw StoriesServiceError.supabaseNotConfigured
        }
        
        let response: [SupabaseStory] = try await supabase
            .from("stories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .neq("status", value: "archived")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.map { $0.toStory() }
    }
    
    func fetchStories(userId: UUID, limit: Int, offset: Int) async throws -> [Story] {
        guard let supabase = supabase else {
            throw StoriesServiceError.supabaseNotConfigured
        }
        
        let response: [SupabaseStory] = try await supabase
            .from("stories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .neq("status", value: "archived")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return response.map { $0.toStory() }
    }
    
    func fetchStory(id: UUID) async throws -> Story? {
        guard let supabase = supabase else {
            throw StoriesServiceError.supabaseNotConfigured
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
    
    func createStory(_ story: Story, userId: UUID) async throws -> Story {
        guard let supabase = supabase else {
            throw StoriesServiceError.supabaseNotConfigured
        }
        
        let supabaseStory = SupabaseStory.fromStory(story, userId: userId)
        
        let response: SupabaseStory = try await supabase
            .from("stories")
            .insert(supabaseStory)
            .select()
            .single()
            .execute()
            .value
        
        return response.toStory()
    }
    
    /// Мягкое удаление: проставляет status = "archived" в Supabase (запись не удаляется физически).
    func softDeleteStory(id: UUID) async throws {
        guard let supabase = supabase else {
            throw StoriesServiceError.supabaseNotConfigured
        }
        try await supabase
            .from("stories")
            .update(["status": "archived"])
            .eq("id", value: id)
            .execute()
    }
    
    func fetchDailyFreeStories(modelContext: ModelContext? = nil) async throws -> [Story] {
        // Сначала проверяем кеш, если передан ModelContext
        if let modelContext = modelContext {
            if let cachedStories = DailyFreeStoriesCacheService.shared.getCachedStories(modelContext: modelContext) {
                print("✅ Использованы истории из кеша")
                return cachedStories
            }
        }
        
        // Если кеша нет или ModelContext не передан, загружаем из Supabase
        guard let supabase = supabase else {
            throw StoriesServiceError.supabaseNotConfigured
        }
        
        // Получаем текущую дату в формате YYYY-MM-DD
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let currentDateString = dateFormatter.string(from: Date())
        
        print("📅 Загрузка ежедневных бесплатных историй для даты: \(currentDateString)")
        
        let response: [DailyFreeStory] = try await supabase
            .from("daily_free_stories")
            .select()
            .eq("story_date", value: currentDateString)
            .execute()
            .value
        
        let stories = response.map { $0.toStory() }
        print("✅ Загружено \(stories.count) ежедневных бесплатных историй")
        
        // Сохраняем в кеш, если передан ModelContext
        if let modelContext = modelContext {
            DailyFreeStoriesCacheService.shared.saveStoriesToCache(stories, modelContext: modelContext)
        }
        
        return stories
    }
    
    func generateStory(
        childId: UUID,
        storyType: String,
        storyLength: Int,
        language: String,
        moral: String? = nil,
        accessToken: String
    ) async throws -> Story {
        guard let url = URL(string: "https://fairytalesai-production-6704.up.railway.app/api/v1/stories/generate") else {
            throw StoriesServiceError.invalidURL
        }
        
        var requestBody: [String: Any] = [
            "language": language,
            "child_id": childId.uuidString,
            "story_type": storyType,
            "story_length": storyLength
        ]
        
        if let moral = moral, !moral.isEmpty {
            requestBody["moral"] = moral
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Настраиваем таймаут для запроса (генерация истории может занять время)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120 // 2 минуты
        configuration.timeoutIntervalForResource = 120 // 2 минуты
        
        let session = URLSession(configuration: configuration)
        let (data, response) = try await session.data(for: request)
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 JSON: \(jsonString)")
        }
        print("🔍 Response: \(response)")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StoriesServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error: Status \(httpResponse.statusCode), Message: \(errorMessage)")
            
            // Специальная обработка для ошибки 429 (Too Many Requests)
            if httpResponse.statusCode == 429 {
                // Проверяем заголовок Retry-After
                if let retryAfterHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                   let retrySeconds = Int(retryAfterHeader) {
                    throw StoriesServiceError.rateLimitExceeded(retryAfterSeconds: retrySeconds)
                } else {
                    throw StoriesServiceError.rateLimitExceeded(retryAfterSeconds: nil)
                }
            }
            
            throw StoriesServiceError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let apiResponse = try decoder.decode(StoryAPIResponse.self, from: data)
        
        // Parse UUID from string
        guard let storyId = UUID(uuidString: apiResponse.id) else {
            throw StoriesServiceError.invalidResponse
        }
        
        // Parse date from ISO8601 string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAtDate = dateFormatter.date(from: apiResponse.createdAt) ?? Date()
        
        return Story(
            id: storyId,
            title: apiResponse.title,
            content: apiResponse.content,
            childId: childId,
            theme: apiResponse.storyType,
            duration: apiResponse.storyLength,
            plot: apiResponse.moral,
            createdAt: createdAtDate,
            favoriteStatus: false,
            language: apiResponse.language,
            rating: nil,
            ageCategory: apiResponse.ageCategory
        )
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
    let ageCategory: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case childId = "child_id"
        case createdAt = "created_at"
        case language
        case rating
        case ageCategory = "age_category"
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
            rating: rating,
            ageCategory: ageCategory
            
        )
    }
    
    private func estimateDuration(from content: String) -> Int {
        // Примерная оценка: ~200 слов в минуту чтения
        let wordCount = content.split(separator: " ").count
        return max(1, wordCount / 200)
    }
    
    static func fromStory(_ story: Story, userId: UUID) -> SupabaseStory {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return SupabaseStory(
            id: story.id,
            title: story.title,
            content: story.content,
            childId: story.childId,
            createdAt: dateFormatter.string(from: story.createdAt),
            language: story.language,
            rating: story.rating,
            ageCategory: story.ageCategory
        )
    }
}

// MARK: - Daily Free Story Model
private struct DailyFreeStory: Codable {
    let id: UUID
    let title: String
    let name: String
    let content: String
    let moral: String?
    let ageCategory: String
    let language: String?
    let storyDate: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case content
        case moral
        case ageCategory = "age_category"
        case language
        case storyDate = "story_date"
    }
    
    func toStory() -> Story {
        // Оцениваем длительность на основе контента
        let wordCount = content.split(separator: " ").count
        let estimatedDuration = max(1, wordCount / 200)
        
        // Используем name как theme, если он есть, иначе используем title для определения темы
        let theme = extractTheme(from: name.isEmpty ? title : name)
        
        return Story(
            id: id,
            title: title,
            content: content,
            childId: nil,
            theme: theme,
            duration: estimatedDuration,
            plot: moral,
            createdAt: Date(),
            favoriteStatus: false,
            language: language ?? "en",
            rating: nil,
            ageCategory: ageCategory
        )
    }
    
    private func extractTheme(from text: String) -> String {
        let lowercased = text.lowercased()
        
        // Простая логика определения темы на основе ключевых слов
        if lowercased.contains("space") || lowercased.contains("astronaut") || lowercased.contains("planet") {
            return "Space"
        } else if lowercased.contains("pirate") || lowercased.contains("treasure") || lowercased.contains("ship") {
            return "Pirates"
        } else if lowercased.contains("fairy") || lowercased.contains("magic") || lowercased.contains("spell") {
            return "Fairies"
        } else if lowercased.contains("animal") || lowercased.contains("forest") || lowercased.contains("jungle") {
            return "Animals"
        } else if lowercased.contains("dragon") || lowercased.contains("castle") {
            return "Dragons"
        } else if lowercased.contains("adventure") || lowercased.contains("quest") {
            return "Adventure"
        } else {
            return "Adventure" // Default theme
        }
    }
}

// MARK: - API Response Models
private struct StoryAPIResponse: Decodable {
    let id: String  // UUID as string from API
    let title: String
    let content: String
    let moral: String?
    let language: String
    let storyType: String
    let storyLength: Int
    let createdAt: String
    /// API может отдавать age_category в корне или внутри child
    let ageCategory: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case moral
        case language
        case storyType = "story_type"
        case storyLength = "story_length"
        case createdAt = "created_at"
        case ageCategory = "age_category"
        case child
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        content = try c.decode(String.self, forKey: .content)
        moral = try c.decodeIfPresent(String.self, forKey: .moral)
        language = try c.decode(String.self, forKey: .language)
        storyType = try c.decode(String.self, forKey: .storyType)
        storyLength = try c.decode(Int.self, forKey: .storyLength)
        createdAt = try c.decode(String.self, forKey: .createdAt)
        // age_category может быть в корне или внутри child
        if let atRoot = try c.decodeIfPresent(String.self, forKey: .ageCategory) {
            ageCategory = atRoot
        } else if let child = try c.decodeIfPresent(StoryAPIResponseChild.self, forKey: .child) {
            ageCategory = child.ageCategory
        } else {
            ageCategory = "3-5" // fallback
        }
    }
}

private struct StoryAPIResponseChild: Decodable {
    let ageCategory: String
    
    enum CodingKeys: String, CodingKey {
        case ageCategory = "age_category"
    }
}

enum StoriesServiceError: LocalizedError {
    case supabaseNotConfigured
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case rateLimitExceeded(retryAfterSeconds: Int?)
    
    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "Supabase не настроен. Пожалуйста, заполните конфигурацию."
        case .invalidURL:
            return "Неверный URL для генерации истории."
        case .invalidResponse:
            return "Неверный ответ от сервера."
        case .apiError(let statusCode, let message):
            return "Ошибка API (код \(statusCode)): \(message)"
        case .rateLimitExceeded(let retryAfterSeconds):
            if let seconds = retryAfterSeconds {
                let minutes = seconds / 60
                if minutes > 0 {
                    return "Превышен лимит запросов. Попробуйте снова через \(minutes) \(minutes == 1 ? "минуту" : minutes < 5 ? "минуты" : "минут")."
                } else {
                    return "Превышен лимит запросов. Попробуйте снова через \(seconds) \(seconds == 1 ? "секунду" : seconds < 5 ? "секунды" : "секунд")."
                }
            } else {
                return "Превышен лимит запросов. Пожалуйста, подождите немного и попробуйте снова."
            }
        }
    }
}

