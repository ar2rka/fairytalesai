import Foundation
import SwiftUI
import Supabase
import AuthenticationServices

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
            for await state in supabase.auth.authStateChanges {
                // Проверяем, что сессия существует и не истекла
                if let session = state.session, !session.isExpired {
                    currentUser = session.user
                    isAuthenticated = true // Анонимные пользователи тоже считаются аутентифицированными
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
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign in with Apple using native SignInWithAppleButton credential
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let supabase = supabase else {
            throw AuthError.supabaseNotConfigured
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Get the identity token from Apple credential
            guard let identityTokenData = credential.identityToken,
                  let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
                print("❌ Apple Sign In: Failed to get identity token")
                throw AuthError.appleSignInFailed
            }
            
            print("🔄 Apple Sign In: Attempting to sign in with Supabase...")
            
            // Sign in with Supabase using Apple identity token
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )
            
            print("✅ Apple Sign In: Successfully authenticated")
            print("   User ID: \(session.user.id.uuidString)")
            if let email = session.user.email {
                print("   Email: \(email)")
            }
            
            // Handle full name if provided (Apple only provides this on first sign-in)
            // Note: We'll update user metadata if full name is available
            if let fullName = credential.fullName {
                let givenName = fullName.givenName ?? ""
                let familyName = fullName.familyName ?? ""
                let displayName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
                
                if !displayName.isEmpty {
                    print("📝 Apple Sign In: Full name received: \(displayName)")
                    // Store in user metadata if needed - this is optional
                    // The name can be accessed from credential.fullName on first sign-in
                }
            }
            
            currentUser = session.user
            isAuthenticated = true
        } catch {
            let errorDescription = error.localizedDescription
            print("❌ Apple Sign In Error: \(errorDescription)")
            print("   Error type: \(type(of: error))")
            
            // Provide more helpful error messages
            if errorDescription.contains("invalid") || errorDescription.contains("token") {
                errorMessage = "Apple Sign In failed. Please try again."
            } else if errorDescription.contains("provider") || errorDescription.contains("Apple") {
                errorMessage = "Apple Sign In is not configured. Please contact support."
            } else {
                errorMessage = errorDescription
            }
            
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

