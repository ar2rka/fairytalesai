import Foundation
import SwiftUI

@MainActor
class ChildrenStore: ObservableObject {
    @Published var children: [Child] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let childrenService = ChildrenService.shared
    private let authService = AuthService.shared
    
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
        
        defer { isLoading = false }
        
        do {
            children = try await childrenService.fetchChildren(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Ошибка загрузки детей: \(error.localizedDescription)")
        }
    }
    
    func addChild(_ child: Child) async throws {
        guard let userId = authService.currentUser?.id else {
            throw ChildrenError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let createdChild = try await childrenService.createChild(child, userId: userId)
            children.append(createdChild)
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
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}




