import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUpMode = false
    @State private var showPassword = false
    @State private var showResetPassword = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.purpleGradient)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "book.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        Text("Fairy Tales AI")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        
                        Text(isSignUpMode ? "Создайте аккаунт" : "Добро пожаловать")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            TextField("your.email@example.com", text: $email)
                                .textFieldStyle(LoginTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пароль")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            HStack {
                                if showPassword {
                                    TextField("Введите пароль", text: $password)
                                        .autocapitalization(.none)
                                } else {
                                    SecureField("Введите пароль", text: $password)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                }
                            }
                            .textFieldStyle(LoginTextFieldStyle())
                        }
                        
                        // Confirm Password (only for sign up)
                        if isSignUpMode {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Подтвердите пароль")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                
                                HStack {
                                    if showPassword {
                                        TextField("Подтвердите пароль", text: $confirmPassword)
                                            .autocapitalization(.none)
                                    } else {
                                        SecureField("Подтвердите пароль", text: $confirmPassword)
                                    }
                                }
                                .textFieldStyle(LoginTextFieldStyle())
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Submit Button
                        Button(action: handleSubmit) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUpMode ? "Зарегистрироваться" : "Войти")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                AppTheme.purpleGradient
                                    .cornerRadius(AppTheme.cornerRadius)
                            )
                        }
                        .disabled(authService.isLoading || !isFormValid)
                        .opacity((authService.isLoading || !isFormValid) ? 0.6 : 1.0)
                        
                        // Reset Password (only for sign in)
                        if !isSignUpMode {
                            Button(action: { showResetPassword = true }) {
                                Text("Забыли пароль?")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                        }
                        
                        // Toggle Sign Up / Sign In
                        HStack {
                            Text(isSignUpMode ? "Уже есть аккаунт?" : "Нет аккаунта?")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            Button(action: {
                                isSignUpMode.toggle()
                                authService.errorMessage = nil
                                password = ""
                                confirmPassword = ""
                            }) {
                                Text(isSignUpMode ? "Войти" : "Зарегистрироваться")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .cornerRadius(AppTheme.cornerRadius)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showResetPassword) {
            ResetPasswordView()
        }
    }
    
    private var isFormValid: Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        guard email.contains("@") else { return false }
        
        if isSignUpMode {
            return password.count >= 6 && password == confirmPassword
        } else {
            return password.count >= 6
        }
    }
    
    private func handleSubmit() {
        Task {
            do {
                if isSignUpMode {
                    try await authService.signUp(email: email, password: password)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                // Error is handled by AuthService
            }
        }
    }
}

struct LoginTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppTheme.backgroundColor(for: colorScheme))
            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardBackground(for: colorScheme), lineWidth: 1)
            )
    }
}

struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Введите email для восстановления пароля")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("your.email@example.com", text: $email)
                        .textFieldStyle(LoginTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal)
                    
                    if showSuccess {
                        Text("Ссылка для восстановления пароля отправлена на ваш email")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if let errorMessage = authService.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: handleResetPassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Отправить")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            AppTheme.purpleGradient
                                .cornerRadius(AppTheme.cornerRadius)
                        )
                    }
                    .disabled(isLoading || email.isEmpty || !email.contains("@"))
                    .opacity((isLoading || email.isEmpty || !email.contains("@")) ? 0.6 : 1.0)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle("Восстановление пароля")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryPurple)
                }
            }
        }
    }
    
    private func handleResetPassword() {
        isLoading = true
        Task {
            do {
                try await authService.resetPassword(email: email)
                showSuccess = true
            } catch {
                // Error handled by AuthService
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}

