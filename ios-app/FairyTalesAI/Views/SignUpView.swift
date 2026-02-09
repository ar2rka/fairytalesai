import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
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
                            
                            Text("Sign in with Apple to protect your stories and sync across devices")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        // Sign in with Apple Button - Commented out for now, will be needed in future
                        /*
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
                        */
                        
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .multilineTextAlignment(.center)
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
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                authService.errorMessage = "Failed to get Apple ID credential"
                return
            }
            
            Task {
                do {
                    try await authService.signInWithApple(credential: appleIDCredential)
                    dismiss()
                } catch {
                    // Error is handled by AuthService
                }
            }
        case .failure(let error):
            authService.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthService.shared)
}
