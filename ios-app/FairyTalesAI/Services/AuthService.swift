import Foundation
import SwiftUI
import Supabase
import AuthenticationServices

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isGuestMode = false // No longer using guest mode - we use anonymous auth instead
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var userEmail: String? {
        return currentUser?.email
    }
    
    var isGuest: Bool {
        // Guest mode is false if we have any session (including anonymous)
        return !isAuthenticated
    }
    
    var isAnonymousUser: Bool {
        // Check if current user is anonymous (has session but no email)
        return currentUser?.isAnonymous ?? false
    }
    
    private var supabase: SupabaseClient?
    private var authStateTask: Task<Void, Never>?
    private var isSigningInAnonymously = false // Защита от повторных вызовов
    
    init() {
        print("🚀 AuthService: Инициализация...")
        setupSupabase()
        checkAuthState()
        observeAuthState()
        // Check if user was previously authenticated
        checkPreviousAuthState()
    }
    
    private func checkPreviousAuthState() {
        // No longer using guest mode - we use anonymous auth instead
        isGuestMode = false
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
    
    private func checkAuthState() {
        guard let supabase = supabase else {
            // If Supabase is not configured, cannot authenticate
            isAuthenticated = false
            currentUser = nil
            isGuestMode = false
            return
        }
        
        Task { @MainActor in
            do {
                let session = try await supabase.auth.session
                // Проверяем, что сессия не истекла
                if session.isExpired {
                    // Сессия истекла - выполняем анонимный вход
                    await signInAnonymouslyIfNeeded()
                } else {
                    // Есть активная сессия (анонимная или обычная)
                    currentUser = session.user
                    isAuthenticated = true // Анонимные пользователи тоже считаются аутентифицированными
                    isGuestMode = false
                    print("👤 User ID from session: \(session.user.id.uuidString)")
                    print("   Is anonymous: \(session.user.isAnonymous)")
                    if let email = session.user.email {
                        print("   Email: \(email)")
                    }
                }
            } catch {
                // Нет активной сессии - выполняем анонимный вход
                await signInAnonymouslyIfNeeded()
            }
        }
    }
    
    private func observeAuthState() {
        guard let supabase = supabase else { return }
        
        authStateTask?.cancel()
        authStateTask = Task { @MainActor in
            for await state in await supabase.auth.authStateChanges {
                // Проверяем, что сессия существует и не истекла
                if let session = state.session, !session.isExpired {
                    currentUser = session.user
                    isAuthenticated = true // Анонимные пользователи тоже считаются аутентифицированными
                    isGuestMode = false
                    print("👤 User ID from auth state change: \(session.user.id.uuidString)")
                    print("   Is anonymous: \(session.user.isAnonymous)")
                } else {
                    // Сессия отсутствует или истекла - выполняем анонимный вход
                    await signInAnonymouslyIfNeeded()
                }
            }
        }
    }
    
    /// Выполняет анонимный вход, если нет активной сессии
    private func signInAnonymouslyIfNeeded() async {
        // Защита от повторных одновременных вызовов
        guard !isSigningInAnonymously else {
            return
        }
        
        guard let supabase = supabase else {
            isAuthenticated = false
            currentUser = nil
            isGuestMode = false
            return
        }
        
        isSigningInAnonymously = true
        defer { isSigningInAnonymously = false }
        
        // Проверяем, есть ли уже активная сессия
        do {
            let existingSession = try await supabase.auth.session
            if !existingSession.isExpired {
                // Сессия уже есть и не истекла
                currentUser = existingSession.user
                isAuthenticated = true
                isGuestMode = false
                print("👤 User ID from existing session: \(existingSession.user.id.uuidString)")
                print("   Is anonymous: \(existingSession.user.isAnonymous)")
                if let email = existingSession.user.email {
                    print("   Email: \(email)")
                }
                return
            }
        } catch {
            // Нет сессии, продолжаем с анонимным входом
        }
        
        // Выполняем анонимный вход
        do {
            print("🔄 Начинаем анонимный вход...")
            // В Supabase Swift SDK signInAnonymously может принимать опциональный captchaToken
            let session = try await supabase.auth.signInAnonymously(captchaToken: nil)
            // Поскольку класс @MainActor, можем напрямую обновлять свойства
            currentUser = session.user
            isAuthenticated = true
            isGuestMode = false
            print("✅ Анонимный вход выполнен успешно. User ID: \(session.user.id.uuidString)")
        } catch {
            let errorDescription = error.localizedDescription
            print("❌ Ошибка анонимного входа: \(errorDescription)")
            print("   Тип ошибки: \(type(of: error))")
            
            // Проверяем, может ли быть проблема с настройками Supabase
            if errorDescription.contains("anonymous") || errorDescription.contains("disabled") {
                print("⚠️ ВНИМАНИЕ: Возможно, анонимная регистрация не включена в настройках Supabase!")
                print("   Проверьте: Authentication → Settings → Enable anonymous sign-ins")
            }
            
            // Не устанавливаем isAuthenticated = false, чтобы не блокировать UI
            // Попробуем еще раз при следующем запросе
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
            isAuthenticated = true
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
            let _ = try await supabase.auth.signInWithOAuth(
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
            isAuthenticated = true
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
            // После выхода выполняем анонимный вход для продолжения работы
            currentUser = nil
            isAuthenticated = false
            isGuestMode = false
            // Выполняем анонимный вход для продолжения работы
            await signInAnonymouslyIfNeeded()
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

