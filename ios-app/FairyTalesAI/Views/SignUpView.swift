import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var migrationService: DataMigrationService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isMigrating = false
    @State private var showMigrationProgress = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.purpleGradient)
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Create Your Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            Text("Protect your stories and sync across devices")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        // Sign in with Apple Button
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: handleAppleSignIn
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal, 24)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        
                        // Email/Password Form
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                
                                TextField("your.email@example.com", text: $email)
                                    .textFieldStyle(LoginTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                
                                HStack {
                                    if showPassword {
                                        TextField("Enter password", text: $password)
                                            .autocapitalization(.none)
                                    } else {
                                        SecureField("Enter password", text: $password)
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                    }
                                }
                                .textFieldStyle(LoginTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                
                                HStack {
                                    if showPassword {
                                        TextField("Confirm password", text: $confirmPassword)
                                            .autocapitalization(.none)
                                    } else {
                                        SecureField("Confirm password", text: $confirmPassword)
                                    }
                                }
                                .textFieldStyle(LoginTextFieldStyle())
                            }
                            
                            if let errorMessage = authService.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                            
                            Button(action: handleEmailSignUp) {
                                HStack {
                                    if authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Create Account")
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
                        }
                        .padding(.horizontal, 24)
                        
                        // Migration Progress
                        if showMigrationProgress {
                            VStack(spacing: 16) {
                                ProgressView(value: migrationService.migrationProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primaryPurple))
                                
                                Text("Migrating your data...")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryPurple)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else { return false }
        guard email.contains("@") else { return false }
        return password.count >= 6 && password == confirmPassword
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                do {
                    // For now, show a message that Apple Sign In requires OAuth setup
                    // In production, implement proper OAuth flow
                    authService.errorMessage = "Sign in with Apple requires OAuth configuration. Please use email sign up for now."
                } catch {
                    // Error is handled by AuthService
                }
            }
        case .failure(let error):
            authService.errorMessage = error.localizedDescription
        }
    }
    
    private func handleEmailSignUp() {
        Task {
            do {
                try await authService.signUp(email: email, password: password)
                await handleSuccessfulSignUp()
            } catch {
                // Error is handled by AuthService
            }
        }
    }
    
    private func handleSuccessfulSignUp() async {
        // Check if there's guest data to migrate
        let guestDataManager = GuestDataManager.shared
        if guestDataManager.hasGuestData, let userId = authService.currentUser?.id {
            showMigrationProgress = true
            do {
                try await migrationService.migrateGuestDataToCloud(userId: userId)
                // Migration successful, dismiss after a short delay
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                dismiss()
            } catch {
                // Migration failed, but user is still signed up
                // Show error but allow them to continue
                authService.errorMessage = "Account created, but data migration failed. Your data is still saved locally."
            }
        } else {
            dismiss()
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthService.shared)
        .environmentObject(DataMigrationService.shared)
}
