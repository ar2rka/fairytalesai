import Foundation
import SwiftUI

@MainActor
class ChildrenStore: ObservableObject {
    @Published var children: [Child] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let childrenService = ChildrenService.shared
    private let authService = AuthService.shared
    private var lastLoadTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 минут
    
    var hasProfiles: Bool {
        !children.isEmpty
    }
    
    init() {
        Task {
            await loadChildren()
        }
    }
    
    func loadChildren() async {
        guard let userId = authService.currentUser?.id else {
            children = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { 
            isLoading = false
            lastLoadTime = Date()
        }
        
        do {
            children = try await childrenService.fetchChildren(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка загрузки детей: \(error.localizedDescription)")
        }
    }
    
    /// Умная загрузка: загружает только если кеш пустой или устарел
    func loadChildrenIfNeeded() async {
        // Если данные уже загружаются, не делаем повторный запрос
        if isLoading {
            return
        }
        
        // Если кеш пустой, загружаем обязательно
        if children.isEmpty {
            await loadChildren()
            return
        }
        
        // Если кеш свежий (загружен менее 5 минут назад), используем его
        if let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < cacheValidityDuration {
            return
        }
        
        // Иначе обновляем в фоне без блокировки UI
        await loadChildren()
    }
    
    func addChild(_ child: Child) async throws -> Child {
        guard let userId = authService.currentUser?.id else {
            throw ChildrenError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let createdChild = try await childrenService.createChild(child, userId: userId)
            children.append(createdChild)
            // Обновляем время последней загрузки, так как кеш актуален
            lastLoadTime = Date()
            return createdChild
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateChild(_ child: Child) async throws {
        guard let userId = authService.currentUser?.id else {
            throw ChildrenError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let updatedChild = try await childrenService.updateChild(child, userId: userId)
            if let index = children.firstIndex(where: { $0.id == child.id }) {
                children[index] = updatedChild
                // Обновляем время последней загрузки, так как кеш актуален
                lastLoadTime = Date()
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteChild(_ child: Child) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await childrenService.deleteChild(id: child.id)
            children.removeAll { $0.id == child.id }
            // Обновляем время последней загрузки, так как кеш актуален
            lastLoadTime = Date()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}





