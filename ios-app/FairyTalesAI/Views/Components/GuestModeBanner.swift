import SwiftUI
import AuthenticationServices

struct GuestModeBanner: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primaryPurple, AppTheme.pastelBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizationManager.shared.settingsSaveMagicForever)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(LocalizationManager.shared.settingsSyncProfiles)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: handleAppleSignIn
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(AppTheme.cornerRadius)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.pastelBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.cornerRadius)
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
                } catch {
                    // Error is handled by AuthService
                }
            }
        case .failure(let error):
            authService.errorMessage = error.localizedDescription
        }
    }
}
