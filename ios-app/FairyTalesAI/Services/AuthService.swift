import Foundation
import SwiftUI
import Supabase
import AuthenticationServices

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isGuestMode = true // Default to guest mode
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var userEmail: String? {
        return currentUser?.email
    }
    
    var isGuest: Bool {
        return isGuestMode && !isAuthenticated
    }
    
    private var supabase: SupabaseClient?
    private var authStateTask: Task<Void, Never>?
    
    init() {
        setupSupabase()
        checkAuthState()
        observeAuthState()
        // Check if user was previously authenticated
        checkPreviousAuthState()
    }
    
    private func checkPreviousAuthState() {
        // If there's no authenticated user, ensure guest mode is enabled
        if !isAuthenticated {
            isGuestMode = true
        } else {
            isGuestMode = false
        }
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
        guard let supabase = supabase else {
            // If Supabase is not configured, stay in guest mode
            isGuestMode = true
            isAuthenticated = false
            return
        }
        
        Task {
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    currentUser = session.user
                    isAuthenticated = !session.user.isAnonymous
                    isGuestMode = !isAuthenticated
                }
            } catch {
                // Нет активной сессии - это нормально, остаемся в guest mode
                await MainActor.run {
                    isAuthenticated = false
                    currentUser = nil
                    isGuestMode = true
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
                    isGuestMode = !isAuthenticated
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
            isAuthenticated = !response.user.isAnonymous
            isGuestMode = false
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign in with Apple using OAuth
    /// Note: This requires proper OAuth setup in Supabase dashboard
    /// You need to configure Apple as an OAuth provider in Supabase
    func signInWithApple() async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Sign in with Apple OAuth
            // This will open the system Apple Sign In flow
            // After successful authentication, Supabase will handle the callback
            let url = try await supabase.auth.signInWithOAuth(
                provider: .apple,
                redirectTo: URL(string: "fairytalesai://auth-callback")!
            )
            
            // Open the OAuth URL in Safari/WebView
            // In a real implementation, you'd use ASWebAuthenticationSession
            // For now, we'll throw an error indicating OAuth setup is needed
            // In production, implement proper OAuth flow with URL handling
            throw AuthError.appleSignInFailed
        } catch {
            errorMessage = "Sign in with Apple requires OAuth configuration. Please use email sign up for now."
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
            isAuthenticated = !response.user.isAnonymous
            isGuestMode = false
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
            isGuestMode = true
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
    case appleSignInFailed
    
    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "Supabase не настроен. Пожалуйста, заполните конфигурацию."
        case .appleSignInFailed:
            return "Не удалось выполнить вход через Apple. Пожалуйста, попробуйте снова."
        }
    }
}

