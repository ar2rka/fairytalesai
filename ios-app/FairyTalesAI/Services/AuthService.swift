import Foundation
import SwiftUI
import Supabase

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var userEmail: String? {
        return currentUser?.email
    }
    
    private var supabase: SupabaseClient?
    private var authStateTask: Task<Void, Never>?
    
    init() {
        setupSupabase()
        checkAuthState()
        observeAuthState()
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
    
    private func checkAuthState() {
        guard let supabase = supabase else { return }
        
        Task {
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    currentUser = session.user
                    isAuthenticated = session.user != nil
                }
            } catch {
                // Нет активной сессии - это нормально
                await MainActor.run {
                    isAuthenticated = false
                    currentUser = nil
                }
            }
        }
    }
    
    private func observeAuthState() {
        guard let supabase = supabase else { return }
        
        authStateTask?.cancel()
        authStateTask = Task {
            for await state in await supabase.auth.authStateChanges {
                await MainActor.run {
                    currentUser = state.session?.user
                    isAuthenticated = state.session?.user != nil
                }
            }
        }
    }
    
    func signUp(email: String, password: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            currentUser = response.user
            isAuthenticated = response.user != nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            currentUser = response.user
            isAuthenticated = response.user != nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}

enum AuthError: LocalizedError {
    case supabaseNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "Supabase не настроен. Пожалуйста, заполните конфигурацию."
        }
    }
}

