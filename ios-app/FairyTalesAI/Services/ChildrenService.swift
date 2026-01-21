import Foundation
import Supabase

@MainActor
class ChildrenService: ObservableObject {
    static let shared = ChildrenService()
    
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
    
    func fetchChildren(userId: UUID) async throws -> [Child] {
        guard let supabase = supabase else {
            throw ChildrenError.supabaseNotConfigured
        }
        
        let response: [SupabaseChild] = try await supabase
            .from("children")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.map { $0.toChild() }
    }
    
    func fetchChild(id: UUID) async throws -> Child? {
        guard let supabase = supabase else {
            throw ChildrenError.supabaseNotConfigured
        }
        
        let response: SupabaseChild? = try await supabase
            .from("children")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return response?.toChild()
    }
    
    func createChild(_ child: Child, userId: UUID) async throws -> Child {
        guard let supabase = supabase else {
            throw ChildrenError.supabaseNotConfigured
        }
        
        let supabaseChild = SupabaseChild.fromChild(child, userId: userId)
        
        let response: SupabaseChild = try await supabase
            .from("children")
            .insert(supabaseChild)
            .select()
            .single()
            .execute()
            .value
        
        return response.toChild()
    }
    
    func updateChild(_ child: Child, userId: UUID) async throws -> Child {
        guard let supabase = supabase else {
            throw ChildrenError.supabaseNotConfigured
        }
        
        let supabaseChild = SupabaseChild.fromChild(child, userId: userId)
        
        let response: SupabaseChild = try await supabase
            .from("children")
            .update(supabaseChild)
            .eq("id", value: child.id)
            .select()
            .single()
            .execute()
            .value
        
        return response.toChild()
    }
    
    func deleteChild(id: UUID) async throws {
        guard let supabase = supabase else {
            throw ChildrenError.supabaseNotConfigured
        }
        
        try await supabase
            .from("children")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Supabase Child Model
private struct SupabaseChild: Codable {
    let id: UUID
    let name: String
    let age: Int?
    let gender: String
    let interests: [String]
    let ageCategory: String
    let userId: UUID?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case gender
        case interests
        case ageCategory = "age_category"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    func toChild() -> Child {
        // Parse dates - Supabase returns ISO8601 format
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var createdAtDate = Date()
        var updatedAtDate = Date()
        
        if let parsedDate = dateFormatter.date(from: createdAt) {
            createdAtDate = parsedDate
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let parsedDate = dateFormatter.date(from: createdAt) {
                createdAtDate = parsedDate
            }
        }
        
        if let parsedDate = dateFormatter.date(from: updatedAt) {
            updatedAtDate = parsedDate
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let parsedDate = dateFormatter.date(from: updatedAt) {
                updatedAtDate = parsedDate
            }
        }
        
        guard let ageCategory = AgeCategory(rawValue: ageCategory) else {
            // Fallback to default if parsing fails
            fatalError("Invalid age category: \(ageCategory)")
        }
        
        // Конвертируем старые значения пола для обратной совместимости
        let normalizedGender: String
        switch gender.lowercased() {
        case "boy":
            normalizedGender = "male"
        case "girl":
            normalizedGender = "female"
        default:
            normalizedGender = gender
        }
        
        return Child(
            id: id,
            name: name,
            gender: normalizedGender,
            ageCategory: ageCategory,
            interests: interests,
            userId: userId,
            createdAt: createdAtDate,
            updatedAt: updatedAtDate
        )
    }
    
    static func fromChild(_ child: Child, userId: UUID?) -> SupabaseChild {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return SupabaseChild(
            id: child.id,
            name: child.name,
            age: nil, // Age field is not used, only age_category
            gender: child.gender,
            interests: child.interests,
            ageCategory: child.ageCategory.rawValue,
            userId: userId ?? child.userId,
            createdAt: dateFormatter.string(from: child.createdAt),
            updatedAt: dateFormatter.string(from: child.updatedAt)
        )
    }
}

enum ChildrenError: LocalizedError {
    case supabaseNotConfigured
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "Supabase не настроен. Пожалуйста, заполните конфигурацию."
        case .userNotAuthenticated:
            return "Ошибка авторизации пользователя."

        }
    }
}

